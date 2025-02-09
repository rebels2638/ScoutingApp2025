import 'package:flutter/material.dart';
import 'main.dart';
import '../services/telemetry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'theme/app_theme.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDevMode = false;
  int? _teamNumber;
  bool _autoIncrementMatch = true;
  bool _confirmBeforeSaving = true;
  String _defaultMatchType = 'Qualification';
  bool _vibrateOnAction = true;
  
  static const String _teamNumberKey = 'selected_team_number';
  static const String _autoIncrementKey = 'auto_increment_match';
  static const String _confirmSaveKey = 'confirm_before_saving';
  static const String _defaultMatchTypeKey = 'default_match_type';
  static const String _vibrateKey = 'vibrate_on_action';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = await TelemetryService.isDevModeEnabled();
    
    setState(() {
      _isDevMode = isEnabled;
      _teamNumber = prefs.getInt(_teamNumberKey);
      _autoIncrementMatch = prefs.getBool(_autoIncrementKey) ?? true;
      _confirmBeforeSaving = prefs.getBool(_confirmSaveKey) ?? true;
      _defaultMatchType = prefs.getString(_defaultMatchTypeKey) ?? 'Qualification';
      _vibrateOnAction = prefs.getBool(_vibrateKey) ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Team Section
        if (_teamNumber != null) ...[
          _buildSection(
            title: 'Team',
            icon: Icons.groups,
            children: [
              ListTile(
                title: Text('Team $_teamNumber'),
                subtitle: const Text('Change team number'),
                trailing: const Icon(Icons.edit),
                onTap: _changeTeamNumber,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Appearance Section
        _buildSection(
          title: 'Appearance',
          icon: Icons.palette,
          children: [
            SwitchListTile(
              title: const Text('Dark Mode (AMOLED)'),
              subtitle: const Text('Use pure black dark theme'),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (bool value) {
                ThemeProvider.of(context).toggleTheme();
              },
            ),
          ],
        ),

        // Behavior Section
        _buildSection(
          title: 'Behavior',
          icon: Icons.tune,
          children: [
            SwitchListTile(
              title: const Text('Auto-increment Match Number'),
              subtitle: const Text('Automatically increase match number after saving'),
              value: _autoIncrementMatch,
              onChanged: (value) async {
                await _saveSetting(_autoIncrementKey, value);
                setState(() => _autoIncrementMatch = value);
              },
            ),
            SwitchListTile(
              title: const Text('Confirm Before Saving'),
              subtitle: const Text('Show confirmation dialog when saving records'),
              value: _confirmBeforeSaving,
              onChanged: (value) async {
                await _saveSetting(_confirmSaveKey, value);
                setState(() => _confirmBeforeSaving = value);
              },
            ),
            ListTile(
              title: const Text('Default Match Type'),
              subtitle: Text(_defaultMatchType),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showMatchTypeDialog(),
            ),
            SwitchListTile(
              title: const Text('Haptic Feedback'),
              subtitle: const Text('Vibrate on actions like saving'),
              value: _vibrateOnAction,
              onChanged: (value) async {
                await _saveSetting(_vibrateKey, value);
                setState(() => _vibrateOnAction = value);
              },
            ),
          ],
        ),

        // Developer Section
        _buildSection(
          title: 'Developer',
          icon: Icons.code,
          children: [
            SwitchListTile(
              title: const Text('Enable Telemetry Logging'),
              subtitle: const Text('Log detailed app usage data'),
              value: _isDevMode,
              onChanged: (value) async {
                await TelemetryService.setDevModeEnabled(value);
                await TelemetryService().setEnabled(value);
                setState(() => _isDevMode = value);

                if (!value && mounted) {
                  final myAppState = context.findAncestorStateOfType<MyAppState>();
                  if (myAppState?.telemetryVisible ?? false) {
                    myAppState?.toggleTelemetry(false);
                  }
                }
              },
            ),
            ListTile(
              title: const Text('Export Debug Logs'),
              subtitle: const Text('Save detailed logs to file'),
              trailing: const Icon(Icons.download),
              enabled: _isDevMode,
              onTap: _isDevMode ? () => _exportDebugLogs() : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showMatchTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Match Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Practice'),
              value: 'Practice',
              groupValue: _defaultMatchType,
              onChanged: (value) async {
                await _saveSetting(_defaultMatchTypeKey, value);
                setState(() => _defaultMatchType = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Qualification'),
              value: 'Qualification',
              groupValue: _defaultMatchType,
              onChanged: (value) async {
                await _saveSetting(_defaultMatchTypeKey, value);
                setState(() => _defaultMatchType = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Playoff'),
              value: 'Playoff',
              groupValue: _defaultMatchType,
              onChanged: (value) async {
                await _saveSetting(_defaultMatchTypeKey, value);
                setState(() => _defaultMatchType = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDebugLogs() async {
    // Implement debug log export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug logs exported')),
    );
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

  void _triggerHaptic() async {
    if (_vibrateOnAction) {
      switch (Theme.of(context).platform) {
        case TargetPlatform.iOS:
          await HapticFeedback.mediumImpact();
          break;
        case TargetPlatform.android:
          await HapticFeedback.vibrate();
          break;
        default:
          break;
      }
    }
  }
}
