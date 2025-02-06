import 'package:flutter/material.dart';
import 'services/ble_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

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
            ],
          ),
        ),
        if (_isCentral) ...[
          ElevatedButton(
            onPressed: () {
              if (_bleService.isScanning) {
                _bleService.stopScanning();
              } else {
                _bleService.startScanning();
              }
              setState(() {});
            },
            child: Text(_bleService.isScanning ? 'Stop Scanning' : 'Start Scanning'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = _discoveredDevices[index];
                return ListTile(
                  title: Text(device.name.isEmpty ? 'Unknown Device' : device.name),
                  subtitle: Text(device.id),
                  trailing: ElevatedButton(
                    onPressed: () => _bleService.connectToDevice(device),
                    child: Text('Connect'),
                  ),
                );
              },
            ),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: () {
              if (_bleService.isAdvertising) {
                _bleService.stopAdvertising();
              } else {
                _bleService.startAdvertising();
              }
              setState(() {});
            },
            child: Text(_bleService.isAdvertising ? 'Stop Advertising' : 'Start Advertising'),
          ),
          if (_bleService.isConnected)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Connected to central device',
                  style: TextStyle(color: Colors.green)),
            ),
        ],
      ],
    );
  }
} 