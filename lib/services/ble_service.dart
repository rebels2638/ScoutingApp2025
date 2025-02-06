import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../data.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  bool _isScanning = false;
  bool _isCentral = false;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  final _deviceController = StreamController<DiscoveredDevice>.broadcast();
  
  // Service and characteristic UUIDs
  static const String serviceUuid = "2638-0000-1000-8000-00805F9B34FB";
  static const String characteristicUuid = "2638-0001-1000-8000-00805F9B34FB";
  
  Stream<DiscoveredDevice> get deviceStream => _deviceController.stream;
  bool get isScanning => _isScanning;
  bool get isCentral => _isCentral;

  String? _connectedDeviceId;
  bool _isAdvertising = false;
  StreamController<ConnectionStateUpdate> _connectionStateController = 
      StreamController<ConnectionStateUpdate>.broadcast();
  
  Stream<ConnectionStateUpdate> get connectionStateStream => 
      _connectionStateController.stream;
  
  bool get isConnected => _connectedDeviceId != null;
  bool get isAdvertising => _isAdvertising;

  BleService._internal();

  Future<void> initialize() async {
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothAdvertise.request();
    await Permission.location.request();
  }

  void setCentralMode(bool isCentral) {
    _isCentral = isCentral;
  }

  Future<void> startScanning() async {
    if (_isScanning) return;
    
    _isScanning = true;
    _scanSubscription = _ble.scanForDevices(
      withServices: [Uuid.parse(serviceUuid)],
    ).listen(
      (device) => _deviceController.add(device),
      onError: (error) => print('Scanning error: $error'),
    );
  }

  Future<void> stopScanning() async {
    _isScanning = false;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<void> startAdvertising() async {
    if (!_isCentral && !_isAdvertising) {
      try {
        // Create a GATT server
        final characteristic = QualifiedCharacteristic(
          serviceId: Uuid.parse(serviceUuid),
          characteristicId: Uuid.parse(characteristicUuid),
          deviceId: '',  // Empty for advertising
        );

        // Start advertising the service
        await _ble.publishCharacteristic(
          characteristic,
          properties: CharacteristicProperties(
            write: true,
            read: true,
            notify: true,
          ),
          permissions: CharacteristicPermissions(
            write: true,
            read: true,
          ),
          initialValue: [0],
        );
        
        _isAdvertising = true;
      } catch (e) {
        print('Error advertising: $e');
        rethrow;
      }
    }
  }

  Future<void> stopAdvertising() async {
    if (_isAdvertising) {
      try {
        final characteristic = QualifiedCharacteristic(
          serviceId: Uuid.parse(serviceUuid),
          characteristicId: Uuid.parse(characteristicUuid),
          deviceId: '',
        );
        await _ble.unpublishCharacteristic(characteristic);
      } catch (e) {
        print('Error stopping advertisement: $e');
      } finally {
        _isAdvertising = false;
      }
    }
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    if (_isCentral) {
      await _connectionSubscription?.cancel();
      
      _connectionSubscription = _ble.connectToDevice(
        id: device.id,
        connectionTimeout: const Duration(seconds: 5),
      ).listen(
        (connectionState) {
          _connectionStateController.add(connectionState);
          if (connectionState.connectionState == DeviceConnectionState.connected) {
            _connectedDeviceId = device.id;
          } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
            _connectedDeviceId = null;
          }
        },
        onError: (error) {
          print('Connection error: $error');
          _connectedDeviceId = null;
        },
      );
    }
  }

  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    _connectedDeviceId = null;
  }

  Future<void> sendMatchData(ScoutingRecord record) async {
    if (!_isCentral && _connectedDeviceId != null) {
      final csvData = record.toCsvRow();
      final characteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse(serviceUuid),
        characteristicId: Uuid.parse(characteristicUuid),
        deviceId: _connectedDeviceId!,
      );
      
      try {
        await _ble.writeCharacteristicWithResponse(
          characteristic,
          value: csvData.toString().codeUnits,
        );
      } catch (e) {
        print('Error sending data: $e');
        rethrow;
      }
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _deviceController.close();
  }
} 