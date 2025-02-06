import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _bleService.deviceStream.listen((device) {
      setState(() {
        if (!_discoveredDevices.any((d) => d.id == device.id)) {
          _discoveredDevices.add(device);
        }
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

  Future<void> _checkAndRequestPermissions() async {
    if (!await _bleService.hasRequiredPermissions()) {
      if (_bleService.needsLocationPermission) {
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
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text('Open Settings'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
              ),
            ],
          ),
        );
        return;
      }
      await _bleService.initialize();
    }
  }

  Future<void> _toggleAdvertising() async {
    try {
      if (_bleService.isAdvertising) {
        await _bleService.stopAdvertising();
        _showSnackBar('Stopped advertising');
      } else {
        // Check permissions before advertising
        await _checkAndRequestPermissions();
        if (await _bleService.hasRequiredPermissions()) {
          await _bleService.startAdvertising();
          _showSnackBar('Device is now discoverable');
        } else {
          _showSnackBar('Required permissions not granted', isError: true);
        }
      }
      setState(() {});
    } catch (e) {
      _showSnackBar('Failed to toggle advertising: $e', isError: true);
    }
  }

  Future<void> _toggleScanning() async {
    try {
      if (_bleService.isScanning) {
        await _bleService.stopScanning();
        _showSnackBar('Stopped scanning');
      } else {
        // Check permissions before scanning
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
                        // Clear discovered devices when switching modes
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
                ? Center(child: Text('No devices found'))
                : ListView.builder(
                    itemCount: _discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = _discoveredDevices[index];
                      return ListTile(
                        leading: Icon(Icons.bluetooth),
                        title: Text(device.name.isEmpty ? 'Unknown Scouter' : device.name),
                        subtitle: Text(device.id),
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
    _bleService.dispose();
    super.dispose();
  }
} 