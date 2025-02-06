import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../data.dart';
import '../services/telemetry_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

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
  static const String serviceUuid = "26380000-1000-8000-0000-805F9B34FB00";
  static const String characteristicUuid = "26380001-1000-8000-0000-805F9B34FB00";
  
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
    // Check platform
    if (Platform.isAndroid) {
      // Android needs location permission for BLE scanning
      final locationStatus = await Permission.location.status;
      if (locationStatus.isDenied) {
        // Show rationale before requesting
        bool shouldShowRationale = await Permission.location.shouldShowRequestRationale;
        if (shouldShowRationale) {
          // Store this in a field so the UI can show an explanation
          _needsLocationPermission = true;
          return;
        }
        await Permission.location.request();
      }
    }

    // Request Bluetooth permissions for both platforms
    if (Platform.isAndroid) {
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothAdvertise.request();
    } else if (Platform.isIOS) {
      await Permission.bluetooth.request();
    }
  }

  // Add this method to check if all required permissions are granted
  Future<bool> hasRequiredPermissions() async {
    if (Platform.isAndroid) {
      final location = await Permission.location.status;
      final bluetooth = await Permission.bluetooth.status;
      final bluetoothScan = await Permission.bluetoothScan.status;
      final bluetoothConnect = await Permission.bluetoothConnect.status;
      final bluetoothAdvertise = await Permission.bluetoothAdvertise.status;

      return location.isGranted && 
             bluetooth.isGranted && 
             bluetoothScan.isGranted && 
             bluetoothConnect.isGranted && 
             bluetoothAdvertise.isGranted;
    } else if (Platform.isIOS) {
      final bluetooth = await Permission.bluetooth.status;
      return bluetooth.isGranted;
    }
    return false;
  }

  // Add field to track if we need to show location permission rationale
  bool _needsLocationPermission = false;
  bool get needsLocationPermission => _needsLocationPermission;

  void setCentralMode(bool isCentral) {
    _isCentral = isCentral;
  }

  Future<void> startScanning() async {
    if (!_isScanning && _isCentral) {
      try {
        TelemetryService().logInfo('bluetooth', 'Starting central scanning');
        _isScanning = true;
        _scanSubscription = _ble.scanForDevices(
          withServices: [Uuid.parse(serviceUuid)],
          scanMode: ScanMode.lowLatency,
        ).listen(
          (device) {
            TelemetryService().logInfo('bluetooth', 'Found device: ${device.name}');
            if (!device.name.contains('Central')) {
              _deviceController.add(device);
            }
          },
          onError: (error) {
            TelemetryService().logError('bluetooth', 'Central scanning error: $error');
            print('Central scanning error: $error');
          },
        );
      } catch (e) {
        TelemetryService().logError('bluetooth', 'Failed to start scanning: $e');
        _isScanning = false;
        rethrow;
      }
    }
  }

  Future<void> stopScanning() async {
    if (_isScanning) {
      TelemetryService().logInfo('bluetooth', 'Stopping central scanning');
      _isScanning = false;
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }
  }

  Future<void> startAdvertising() async {
    if (!_isCentral && !_isAdvertising) {
      try {
        TelemetryService().logInfo('bluetooth', 'Starting peripheral advertising');
        
        // Create a unique identifier for this device
        final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        
        // Start scanning for central devices
        _scanSubscription = _ble.scanForDevices(
          withServices: [Uuid.parse(serviceUuid)],
          scanMode: ScanMode.lowLatency,
        ).listen(
          (device) {
            TelemetryService().logInfo('bluetooth', 'Detected device: ${device.name}');
            // Only add central devices
            if (device.name.contains('Central')) {
              _deviceController.add(device);
            }
          },
          onError: (error) {
            TelemetryService().logError('bluetooth', 'Peripheral scanning error: $error');
            print('Peripheral scanning error: $error');
          },
        );
        
        _isAdvertising = true;
        TelemetryService().logInfo('bluetooth', 'Peripheral advertising started');
      } catch (e) {
        TelemetryService().logError('bluetooth', 'Failed to start advertising: $e');
        print('Error starting peripheral mode: $e');
        _isAdvertising = false;
        rethrow;
      }
    }
  }

  Future<void> stopAdvertising() async {
    if (_isAdvertising) {
      TelemetryService().logInfo('bluetooth', 'Stopping peripheral advertising');
      await _scanSubscription?.cancel();
      _isAdvertising = false;
      TelemetryService().logInfo('bluetooth', 'Peripheral advertising stopped');
    }
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