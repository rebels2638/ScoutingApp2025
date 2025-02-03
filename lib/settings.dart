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
    if (mounted) {
      setState(() {
        _isDevMode = isEnabled;
      });
      /*
      if (isEnabled) {
      await TelemetryService().setEnabled(true);
      */
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
                  // update dev mode setting
                  await TelemetryService.setDevModeEnabled(value);
                  await TelemetryService().setEnabled(value);
                  
                  // update local state
                  setState(() {
                    _isDevMode = value;
                  });

                  // get MyAppState, update telemetry if needed
                  final myAppState = context.findAncestorStateOfType<MyAppState>();
                  if (myAppState != null) {
                    if (!value && myAppState.telemetryVisible) {
                      myAppState.toggleTelemetry(false);
                    }
                  }

                  // show feedback
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Developer mode ${value ? 'enabled' : 'disabled'}'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
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
