import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../data.dart';
import '../services/telemetry_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  bool _isScanning = false;
  bool _isCentral = false;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamController<DiscoveredDevice>? _deviceController;
  StreamController<void>? _clearController;
  StreamController<ConnectionStateUpdate>? _connectionStateController;
  
  // service and characteristic UUIDs
  static const String serviceUuid = "26380000-1000-8000-0000-805F9B34FB00";
  static const String characteristicUuid = "26380001-1000-8000-0000-805F9B34FB00";
  
  Stream<DiscoveredDevice> get deviceStream {
    _deviceController ??= StreamController<DiscoveredDevice>.broadcast();
    return _deviceController!.stream;
  }
  
  Stream<void> get clearStream {
    _clearController ??= StreamController<void>.broadcast();
    return _clearController!.stream;
  }
  
  Stream<ConnectionStateUpdate> get connectionStateStream {
    _connectionStateController ??= StreamController<ConnectionStateUpdate>.broadcast();
    return _connectionStateController!.stream;
  }
  
  bool get isScanning => _isScanning;
  bool get isCentral => _isCentral;

  String? _connectedDeviceId;
  bool _isAdvertising = false;
  
  bool get isConnected => _connectedDeviceId != null;
  bool get isAdvertising => _isAdvertising;

  // Add a constant for identifying our app's devices
  static const String deviceNamePrefix = "2638Scout";
  
  BleService._internal();

  Future<void> initialize() async {
    TelemetryService().logInfo('bluetooth', 'Initializing BLE service');
    try {
      if (Platform.isAndroid) {
        // get Android version
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        TelemetryService().logInfo('bluetooth', 'Android SDK version: $sdkInt');

        // android 21/sdk31 and above: only need new perms
        if (sdkInt >= 31) {
          TelemetryService().logInfo('bluetooth', 'Using new Bluetooth permissions for Android 12+');
          
          // request location perm: needed for scanning
          var locationStatus = await Permission.location.status;
          if (!locationStatus.isGranted) {
            locationStatus = await Permission.location.request();
            TelemetryService().logInfo('bluetooth', 'Location permission result: ${locationStatus.name}');
            if (!locationStatus.isGranted) {
              throw Exception('Location permission denied');
            }
          }

          // request new bt perms
          final permissions = [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
          ];

          for (var permission in permissions) {
            var status = await permission.status;
            if (!status.isGranted) {
              status = await permission.request();
              TelemetryService().logInfo('bluetooth', '${permission.toString()} result: ${status.name}');
              if (!status.isGranted) {
                throw Exception('${permission.toString()} denied');
              }
            }
          }
        } else {
          // older android versions: need legacy perms
          TelemetryService().logInfo('bluetooth', 'Using legacy Bluetooth permissions');
          
          final permissions = [
            Permission.location,
            Permission.bluetooth,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
          ];

          for (var permission in permissions) {
            var status = await permission.status;
            if (!status.isGranted) {
              status = await permission.request();
              TelemetryService().logInfo('bluetooth', '${permission.toString()} result: ${status.name}');
              if (!status.isGranted) {
                throw Exception('${permission.toString()} denied');
              }
            }
          }
        }

        TelemetryService().logInfo('bluetooth', 'All permissions successfully granted');
      } else if (Platform.isIOS) {
        // ios bluetooth perm handling
        final bluetoothStatus = await Permission.bluetooth.request();
        TelemetryService().logInfo('bluetooth', 'iOS Bluetooth permission result: ${bluetoothStatus.name}');
        
        if (!bluetoothStatus.isGranted) {
          TelemetryService().logError('bluetooth', 'Bluetooth permission denied on iOS');
          throw Exception('Bluetooth permission denied');
        }
      }
    } catch (e) {
      TelemetryService().logError('bluetooth', 'Error initializing BLE service: $e');
      rethrow;
    }
  }

  Future<bool> hasRequiredPermissions() async {
    try {
      TelemetryService().logInfo('bluetooth_permissions', 'Checking required permissions');
      if (Platform.isAndroid) {
        // get android version
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        if (sdkInt >= 31) {
          // android 12+: only check new perms
          final location = await Permission.location.status;
          final bluetoothScan = await Permission.bluetoothScan.status;
          final bluetoothConnect = await Permission.bluetoothConnect.status;
          final bluetoothAdvertise = await Permission.bluetoothAdvertise.status;

          TelemetryService().logInfo('bluetooth_permissions', 
            'Android 12+ Permissions Status:\n' +
            'Location: ${location.name}\n' +
            'BluetoothScan: ${bluetoothScan.name}\n' +
            'BluetoothConnect: ${bluetoothConnect.name}\n' +
            'BluetoothAdvertise: ${bluetoothAdvertise.name}'
          );

          return location.isGranted && 
                 bluetoothScan.isGranted && 
                 bluetoothConnect.isGranted && 
                 bluetoothAdvertise.isGranted;
        } else {
          // older android versions: check all perms
          final location = await Permission.location.status;
          final bluetooth = await Permission.bluetooth.status;
          final bluetoothScan = await Permission.bluetoothScan.status;
          final bluetoothConnect = await Permission.bluetoothConnect.status;
          final bluetoothAdvertise = await Permission.bluetoothAdvertise.status;

          TelemetryService().logInfo('bluetooth_permissions', 
            'Legacy Android Permissions Status:\n' +
            'Location: ${location.name}\n' +
            'Bluetooth: ${bluetooth.name}\n' +
            'BluetoothScan: ${bluetoothScan.name}\n' +
            'BluetoothConnect: ${bluetoothConnect.name}\n' +
            'BluetoothAdvertise: ${bluetoothAdvertise.name}'
          );

          return location.isGranted && 
                 bluetooth.isGranted && 
                 bluetoothScan.isGranted && 
                 bluetoothConnect.isGranted && 
                 bluetoothAdvertise.isGranted;
        }
      } else if (Platform.isIOS) {
        final bluetooth = await Permission.bluetooth.status;
        TelemetryService().logInfo('bluetooth_permissions', 'iOS Bluetooth Permission: ${bluetooth.name}');
        return bluetooth.isGranted;
      }
      return false;
    } catch (e) {
      TelemetryService().logError('bluetooth_permissions', 'Error checking permissions: $e');
      return false;
    }
  }

  // add field to track if we need to show location permission rationale
  bool _needsLocationPermission = false;
  bool get needsLocationPermission => _needsLocationPermission;

  void setCentralMode(bool isCentral) {
    _isCentral = isCentral;
  }

  // Add method to reset streams
  void _resetStreams() {
    // Close existing controllers
    _deviceController?.close();
    _clearController?.close();
    _connectionStateController?.close();
    
    // Create new controllers
    _deviceController = StreamController<DiscoveredDevice>.broadcast();
    _clearController = StreamController<void>.broadcast();
    _connectionStateController = StreamController<ConnectionStateUpdate>.broadcast();
  }

  Future<void> startScanning() async {
    if (!_isScanning && _isCentral) {
      try {
        // Reset streams before starting new scan
        _resetStreams();
        
        TelemetryService().logInfo('bluetooth', 'Starting central scanning');
        _isScanning = true;
        
        // Signal to clear existing devices
        _clearController?.add(null);
        
        // Create unique identifier for this central device
        final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        final deviceName = "${deviceNamePrefix}_C_$deviceId"; // C for Central
        
        _scanSubscription = _ble.scanForDevices(
          withServices: [],
          scanMode: ScanMode.lowLatency,
        ).listen(
          (device) {
            if (device.name.startsWith('${deviceNamePrefix}_P_')) {
              TelemetryService().logInfo('bluetooth', 
                'Central found peripheral device: ${device.name}\n' +
                'RSSI: ${device.rssi}'
              );
              _deviceController?.add(device);
            }
          },
          onError: (error) {
            TelemetryService().logError('bluetooth', 'Central scanning error: $error');
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
      // Signal to clear the device list
      _clearController?.add(null);
    }
  }

  Future<void> startAdvertising() async {
    if (!_isCentral && !_isAdvertising) {
      try {
        // Reset streams before starting advertising
        _resetStreams();
        
        TelemetryService().logInfo('bluetooth', 'Starting peripheral advertising');
        
        // Create unique identifier for this device
        final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        final deviceName = "${deviceNamePrefix}_P_$deviceId"; // P for Peripheral
        
        _isAdvertising = true;
        TelemetryService().logInfo('bluetooth', 'Peripheral mode active, deviceId: $deviceName');
        
        // Start scanning for central devices
        _scanSubscription = _ble.scanForDevices(
          withServices: [], 
          scanMode: ScanMode.lowLatency,
        ).listen(
          (device) {
            // Only add devices with our app's prefix and central identifier
            if (device.name.startsWith('${deviceNamePrefix}_C_')) {
              TelemetryService().logInfo('bluetooth', 
                'Peripheral detected central device: ${device.name}\n' +
                'RSSI: ${device.rssi}'
              );
              _deviceController?.add(device);
            }
          },
          onError: (error) {
            TelemetryService().logError('bluetooth', 'Peripheral scanning error: $error');
          },
        );
      } catch (e) {
        TelemetryService().logError('bluetooth', 'Failed to start advertising: $e');
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
    
    // set device name based on role
    final deviceName = _isCentral ? 'Central-${device.id}' : 'Peripheral-${device.id}';
    
    _connectionSubscription = _ble.connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 5),
    ).listen(
      (connectionState) {
        _connectionStateController?.add(connectionState);
        
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
                // handle incoming data
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
      
      // split data into chunks if needed (BLE has packet size limits)
      final chunkSize = 512; // typical BLE packet size limit
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
    _deviceController?.close();
    _clearController?.close();
    _connectionStateController?.close();
    
    _deviceController = null;
    _clearController = null;
    _connectionStateController = null;
  }
} 