import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'services/ble_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'services/telemetry_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final BleService _bleService = BleService();
  List<DiscoveredDevice> _discoveredDevices = [];
  bool _isCentral = false;
  String? _connectionStatus;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeBle();
  }

  Future<void> _initializeBle() async {
    try {
      // Check platform support first
      if (!await _isBleSupported()) {
        setState(() {
          _error = 'Bluetooth LE is not supported on this device';
        });
        return;
      }

      // Initialize BLE service
      await _bleService.initialize();
      
      // Set up listeners only after successful initialization
      _setupListeners();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize Bluetooth: $e';
      });
      TelemetryService().logError('bluetooth_page', 'Initialization failed: $e');
    }
  }

  Future<bool> _isBleSupported() async {
    try {
      final flutterReactiveBle = FlutterReactiveBle();
      await flutterReactiveBle.statusStream.first;
      return true;
    } catch (e) {
      return false;
    }
  }

  void _setupListeners() {
    _bleService.deviceStream.listen(
      (device) {
        setState(() {
          if (!_discoveredDevices.any((d) => d.id == device.id)) {
            _discoveredDevices.add(device);
          }
        });
      },
      onError: (e) {
        TelemetryService().logError('bluetooth_page', 'Device stream error: $e');
      },
    );

    // Listen for clear signals
    _bleService.clearStream.listen((_) {
      setState(() {
        _discoveredDevices.clear();
      });
    });

    _bleService.connectionStateStream.listen((state) {
      setState(() {
        switch (state.connectionState) {
          case DeviceConnectionState.connecting:
            _connectionStatus = 'Connecting...';
            break;
          case DeviceConnectionState.connected:
            _connectionStatus = 'Connected';
            break;
          case DeviceConnectionState.disconnecting:
            _connectionStatus = 'Disconnecting...';
            break;
          case DeviceConnectionState.disconnected:
            _connectionStatus = 'Disconnected';
            break;
        }
      });
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showBluetoothSettings() async {
    try {
      if (Platform.isIOS) {
        // On iOS, we need to direct users to the system settings
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Enable Bluetooth'),
            content: Text(
              'Please enable Bluetooth in your device settings to use this feature.\n\n'
              'Settings → Bluetooth'
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('Open Settings'),
                onPressed: () {
                  Navigator.pop(context);
                  AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
                },
              ),
            ],
          ),
        );
      } else {
        // On Android, we can directly open Bluetooth settings
        await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
      }
    } catch (e) {
      TelemetryService().logError('bluetooth_page', 'Error opening settings: $e');
      _showSnackBar('Could not open Bluetooth settings', isError: true);
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    TelemetryService().logInfo('bluetooth_page', 'Checking and requesting permissions');
    try {
      if (!await _bleService.hasRequiredPermissions()) {
        if (Platform.isIOS) {
          // iOS-specific permission handling
          final status = await Permission.bluetooth.request();
          if (!status.isGranted) {
            _showBluetoothSettings();
            return;
          }
          
          // Check if Bluetooth is actually enabled
          final ble = FlutterReactiveBle();
          final bleStatus = await ble.statusStream.first;
          if (bleStatus == BleStatus.poweredOff) {
            _showBluetoothSettings();
            return;
          }
        } else {
          // Existing Android permission handling
          if (_bleService.needsLocationPermission) {
            TelemetryService().logInfo('bluetooth_page', 'Showing location permission dialog');
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Location Permission Required'),
                content: Text(
                  'This app needs location permission to scan for nearby Bluetooth devices. ' +
                  'This is required by Android for Bluetooth scanning to work.\n\n' +
                  'The app does not track or store your location.',
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      TelemetryService().logAction('bluetooth_permissions', 'User cancelled permission request');
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Open Settings'),
                    onPressed: () async {
                      TelemetryService().logAction('bluetooth_permissions', 'User opened settings');
                      Navigator.of(context).pop();
                      await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
                    },
                  ),
                ],
              ),
            );
            return;
          }
          await _bleService.initialize();
        }
        
        // Check permissions again after initialization
        if (!await _bleService.hasRequiredPermissions()) {
          _showSnackBar('Please enable Bluetooth and grant required permissions', isError: true);
          return;
        }
      }
      TelemetryService().logInfo('bluetooth_page', 'All required permissions granted');
    } catch (e) {
      TelemetryService().logError('bluetooth_page', 'Error checking permissions: $e');
      _showSnackBar('Error checking permissions: $e', isError: true);
    }
  }

  Future<void> _toggleAdvertising() async {
    try {
      TelemetryService().logAction('bluetooth_page', 'Toggle advertising requested');
      if (_bleService.isAdvertising) {
        await _bleService.stopAdvertising();
        _showSnackBar('Stopped advertising');
      } else {
        // check permissions before advertising
        await _checkAndRequestPermissions();
        if (await _bleService.hasRequiredPermissions()) {
          await _bleService.startAdvertising();
          _showSnackBar('Device is now discoverable');
        } else {
          TelemetryService().logError('bluetooth_page', 'Required permissions not granted for advertising');
          _showSnackBar('Required permissions not granted', isError: true);
        }
      }
      setState(() {});
    } catch (e) {
      TelemetryService().logError('bluetooth_page', 'Failed to toggle advertising: $e');
      _showSnackBar('Failed to toggle advertising: $e', isError: true);
    }
  }

  Future<void> _toggleScanning() async {
    try {
      if (_bleService.isScanning) {
        await _bleService.stopScanning();
        _showSnackBar('Stopped scanning');
      } else {
        // check permissions before scanning
        await _checkAndRequestPermissions();
        if (await _bleService.hasRequiredPermissions()) {
          await _bleService.startScanning();
          _showSnackBar('Started scanning for devices');
        } else {
          _showSnackBar('Required permissions not granted', isError: true);
        }
      }
      setState(() {});
    } catch (e) {
      _showSnackBar('Failed to toggle scanning: $e', isError: true);
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    try {
      await _bleService.connectToDevice(device);
      _showSnackBar('Connecting to ${device.name}...');
    } catch (e) {
      _showSnackBar('Failed to connect: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error state if initialization failed
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _initializeBle();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading state while initializing
    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing Bluetooth...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  TelemetryService().logAction('bluetooth_page', 'Manual permission request initiated');
                  await _bleService.initialize();
                  // check if permissions were granted
                  if (await _bleService.hasRequiredPermissions()) {
                    _showSnackBar('All permissions granted');
                  } else {
                    _showSnackBar('Some permissions are still missing. Please check Settings.', isError: true);
                    // show settings dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Permissions Required'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('The following permissions are required:'),
                            SizedBox(height: 8),
                            Text('• Bluetooth'),
                            Text('• Bluetooth Scan'),
                            Text('• Bluetooth Connect'),
                            Text('• Bluetooth Advertise'),
                            Text('• Location (for Bluetooth scanning)'),
                            SizedBox(height: 16),
                            Text('Please enable all permissions in Settings.'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text('Open Settings'),
                            onPressed: () {
                              Navigator.pop(context);
                              AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
                            },
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: Icon(Icons.security),
                label: Text('Request Permissions'),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Mode: '),
                  ToggleButtons(
                    isSelected: [_isCentral, !_isCentral],
                    onPressed: (index) {
                      setState(() {
                        _isCentral = index == 0;
                        _bleService.setCentralMode(_isCentral);
                        // clear discovered devices when switching modes
                        _discoveredDevices.clear();
                      });
                    },
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Central (Leader)'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Peripheral (Scouter)'),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (_connectionStatus != null)
                Text('Status: $_connectionStatus',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                _isCentral 
                    ? 'Scanning for scouters...' 
                    : 'Waiting for leader to connect...',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        if (_isCentral) ...[
          ElevatedButton(
            onPressed: _toggleScanning,
            child: Text(_bleService.isScanning ? 'Stop Scanning' : 'Start Scanning'),
          ),
          Expanded(
            child: _discoveredDevices.isEmpty
                ? Center(
                    child: Text(
                      'No scouters found yet...',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = _discoveredDevices[index];
                      // Extract device role and ID from name
                      final nameParts = device.name.split('_');
                      final isValidDevice = device.name.startsWith(BleService.deviceNamePrefix);
                      final role = nameParts.length > 1 ? nameParts[1] : 'Unknown';
                      final deviceId = nameParts.length > 2 ? nameParts[2] : 'Unknown';
                      
                      return ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: isValidDevice ? Colors.blue : Colors.grey,
                        ),
                        title: Text(isValidDevice 
                          ? 'Scouting Device ${deviceId.substring(deviceId.length - 4)}' 
                          : device.name.isEmpty ? 'Unknown Device' : device.name
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Role: ${role == "P" ? "Peripheral (Scouter)" : "Central (Leader)"}'),
                            Text('Signal Strength: ${device.rssi} dBm'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToDevice(device),
                          child: Text('Connect'),
                        ),
                      );
                    },
                  ),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: _toggleAdvertising,
            child: Text(_bleService.isAdvertising ? 'Stop Advertising' : 'Make Discoverable'),
          ),
          if (_bleService.isConnected)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  Text('Connected to leader',
                      style: TextStyle(color: Colors.green, fontSize: 16)),
                  Text('Ready to send match data',
                      style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    // Safely dispose of BLE service
    try {
      _bleService.dispose();
    } catch (e) {
      TelemetryService().logError('bluetooth_page', 'Error disposing BLE service: $e');
    }
    super.dispose();
  }
} 