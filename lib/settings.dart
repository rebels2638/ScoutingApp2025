import 'package:flutter/material.dart';
import 'main.dart';
import '../services/telemetry_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDevMode = false;

  @override
  void initState() {
    super.initState();
    _loadDevMode();
  }

  Future<void> _loadDevMode() async {
    final isEnabled = await TelemetryService.isDevModeEnabled();
    setState(() {
      _isDevMode = isEnabled;
    });
    if (isEnabled) {
      await TelemetryService().setEnabled(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // appearance section
        SectionHeader(title: 'Appearance', icon: Icons.palette),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dark Mode (AMOLED)',
                style: TextStyle(fontSize: 16),
              ),
              Switch(
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (bool value) {
                  ThemeProvider.of(context).toggleTheme();
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        //Divider(),
        
        // other section
        SectionHeader(title: 'Other', icon: Icons.miscellaneous_services),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Developer Mode', style: TextStyle(fontSize: 16)),
              Switch(
                value: _isDevMode,
                onChanged: (value) async {
                  await TelemetryService.setDevModeEnabled(value);
                  await TelemetryService().setEnabled(value);
                  setState(() {
                    _isDevMode = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
