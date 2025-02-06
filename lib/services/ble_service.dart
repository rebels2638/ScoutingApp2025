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
    if (!_isScanning && _isCentral) {
      _isScanning = true;
      _scanSubscription = _ble.scanForDevices(
        withServices: [Uuid.parse(serviceUuid)],
        scanMode: ScanMode.lowLatency,
      ).listen(
        (device) {
          // Only add peripheral devices
          if (!device.name.contains('Central')) {
            _deviceController.add(device);
          }
        },
        onError: (error) => print('Central scanning error: $error'),
      );
    }
  }

  Future<void> stopScanning() async {
    _isScanning = false;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<void> startAdvertising() async {
    if (!_isCentral && !_isAdvertising) {
      try {
        // Start scanning for central devices that might want to connect
        _scanSubscription = _ble.scanForDevices(
          withServices: [Uuid.parse(serviceUuid)],
          scanMode: ScanMode.lowLatency,
        ).listen(
          (device) {
            // When we detect a central device, allow it to connect
            _deviceController.add(device);
          },
          onError: (error) => print('Peripheral scanning error: $error'),
        );
        
        _isAdvertising = true;
      } catch (e) {
        print('Error starting peripheral mode: $e');
        _isAdvertising = false;
        rethrow;
      }
    }
  }

  Future<void> stopAdvertising() async {
    _isAdvertising = false;
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    await _connectionSubscription?.cancel();
    
    // Set device name based on role
    final deviceName = _isCentral ? 'Central-${device.id}' : 'Peripheral-${device.id}';
    
    _connectionSubscription = _ble.connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 5),
    ).listen(
      (connectionState) {
        _connectionStateController.add(connectionState);
        
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          _connectedDeviceId = device.id;
          
          // Set up characteristic subscription for receiving data
          if (!_isCentral) {
            final characteristic = QualifiedCharacteristic(
              serviceId: Uuid.parse(serviceUuid),
              characteristicId: Uuid.parse(characteristicUuid),
              deviceId: device.id,
            );
            
            _ble.subscribeToCharacteristic(characteristic).listen(
              (data) {
                // Handle incoming data
                print('Received data from central: ${String.fromCharCodes(data)}');
              },
              onError: (error) => print('Error receiving data: $error'),
            );
          }
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

  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    _connectedDeviceId = null;
  }

  Future<void> sendMatchData(ScoutingRecord record) async {
    if (_connectedDeviceId != null) {
      final csvData = record.toCsvRow();
      final data = csvData.toString().codeUnits;
      
      // Split data into chunks if needed (BLE has packet size limits)
      final chunkSize = 512; // Typical BLE packet size limit
      for (var i = 0; i < data.length; i += chunkSize) {
        final chunk = data.sublist(
          i, 
          i + chunkSize > data.length ? data.length : i + chunkSize
        );
        
        final characteristic = QualifiedCharacteristic(
          serviceId: Uuid.parse(serviceUuid),
          characteristicId: Uuid.parse(characteristicUuid),
          deviceId: _connectedDeviceId!,
        );
        
        try {
          await _ble.writeCharacteristicWithResponse(
            characteristic,
            value: chunk,
          );
        } catch (e) {
          print('Error sending data chunk: $e');
          rethrow;
        }
      }
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _deviceController.close();
  }
} 