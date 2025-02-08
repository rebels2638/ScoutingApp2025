import 'package:flutter/material.dart';
import 'main.dart';
import '../services/telemetry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDevMode = false;
  int? _teamNumber;
  static const String _teamNumberKey = 'selected_team_number';

  @override
  void initState() {
    super.initState();
    _loadDevMode();
    _loadTeamNumber();
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

  Future<void> _loadTeamNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teamNumber = prefs.getInt(_teamNumberKey);
    });
  }

  Future<void> _changeTeamNumber() async {
    if (_teamNumber != null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change Team Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current team number: $_teamNumber'),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to change your team number? '
                'This will reset your API settings.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Reset team data using the global key
                await ApiPageState.globalKey.currentState?.resetTeamData();
                setState(() {
                  _teamNumber = null;
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Team number reset. Please set a new team number in the API tab.'),
                    ),
                  );
                }
              },
              child: const Text('Reset'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Team Section
        if (_teamNumber != null) ...[
          SectionHeader(title: 'Team', icon: Icons.groups),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Card(
              child: ListTile(
                title: Text('Team $_teamNumber'),
                subtitle: const Text('Change team number'),
                trailing: const Icon(Icons.edit),
                onTap: _changeTeamNumber,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

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
        SectionHeader(title: 'Developer', icon: Icons.miscellaneous_services),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Enable Telemetry Logging', style: TextStyle(fontSize: 16)),
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
