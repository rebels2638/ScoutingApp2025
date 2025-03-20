import 'package:flutter/material.dart';
import 'main.dart';
import '../services/telemetry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'dart:io';
import 'widgets/navbar.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDevMode = false;
  int? _teamNumber;
  bool _autoIncrementMatch = true;
  bool _confirmBeforeSaving = true;
  bool _vibrateOnAction = true;
  bool _bluetoothEnabled = false;
  bool _scoutingLeaderEnabled = false;
  bool _refreshButtonEnabled = false;
  bool _keepScreenAwake = false;
  TextEditingController _qrRateLimitController = TextEditingController();
  
  static const String _teamNumberKey = 'selected_team_number';
  static const String _autoIncrementKey = 'auto_increment_match';
  static const String _confirmSaveKey = 'confirm_before_saving';
  static const String _vibrateKey = 'vibrate_on_action';
  static const String _bluetoothEnabledKey = 'bluetooth_enabled';
  static const String _scoutingLeaderKey = 'scouting_leader_enabled';
  static const String _qrRateLimitKey = 'qr_rate_limit';
  static const String _refreshButtonKey = 'refresh_button_enabled';
  static const String _keepScreenAwakeKey = 'keep_screen_awake';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _qrRateLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = await TelemetryService.isDevModeEnabled();
    
    setState(() {
      _isDevMode = isEnabled;
      _teamNumber = prefs.getInt(_teamNumberKey);
      _autoIncrementMatch = prefs.getBool(_autoIncrementKey) ?? true;
      _confirmBeforeSaving = prefs.getBool(_confirmSaveKey) ?? true;
      _vibrateOnAction = prefs.getBool(_vibrateKey) ?? true;
      _bluetoothEnabled = prefs.getBool(_bluetoothEnabledKey) ?? false;
      _scoutingLeaderEnabled = prefs.getBool(_scoutingLeaderKey) ?? true;
      _refreshButtonEnabled = prefs.getBool(_refreshButtonKey) ?? false;
      _keepScreenAwake = prefs.getBool(_keepScreenAwakeKey) ?? false;
      _qrRateLimitController.text = (prefs.getInt(_qrRateLimitKey) ?? 1500).toString();
    });

    // apply screen wake setting
    if (_keepScreenAwake) {
      await _applyScreenWakeLock(true);
    }
  }

  Future<void> _applyScreenWakeLock(bool enable) async {
    try {
      if (enable) {
        // enable screen wake lock with all available flags
        await SystemChannels.platform.invokeMethod('SystemChrome.setEnabledSystemUIMode', 
          SystemUiMode.manual.toString());
        await SystemChannels.platform.invokeMethod('HapticFeedback.vibrate');
        await SystemChannels.platform.invokeMethod('Screen.keepOn', true);
      } else {
        // disable screen wake lock
        await SystemChannels.platform.invokeMethod('SystemChrome.setEnabledSystemUIMode', 
          SystemUiMode.edgeToEdge.toString());
        await SystemChannels.platform.invokeMethod('Screen.keepOn', false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${enable ? 'enable' : 'disable'} screen wake lock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _saveQrRateLimit(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final intValue = int.tryParse(value);
    if (intValue != null && intValue > 0) {
      await prefs.setInt(_qrRateLimitKey, intValue);
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
                subtitle: const Text('Reset team number'),
                trailing: const Icon(Icons.refresh),
                onTap: _resetTeamNumber,
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
            SwitchListTile(
              title: const Text('Haptic Feedback'),
              subtitle: const Text('Vibrate on actions like saving'),
              value: _vibrateOnAction,
              onChanged: (value) async {
                await _saveSetting(_vibrateKey, value);
                setState(() => _vibrateOnAction = value);
              },
            ),
            SwitchListTile(
              title: const Text('Enable Refresh Button'),
              subtitle: const Text('Show refresh button on data page'),
              value: _refreshButtonEnabled,
              onChanged: (value) async {
                await _saveSetting(_refreshButtonKey, value);
                setState(() => _refreshButtonEnabled = value);
              },
            ),
            SwitchListTile(
              title: const Text('Keep Screen Awake'),
              subtitle: const Text('Prevent device from sleeping even on low battery'),
              value: _keepScreenAwake,
              onChanged: _toggleKeepScreenAwake,
            ),
            ListTile(
              title: const Text('QR Scan Rate Limit (ms)'),
              subtitle: const Text('Minimum time between scans. Default value is 1500ms.'),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  controller: _qrRateLimitController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    hintText: '1500',
                  ),
                  onChanged: _saveQrRateLimit,
                ),
              ),
            ),
          ],
        ),

        // Roles Section
        _buildSection(
          title: 'Roles',
          icon: Icons.badge,
          children: [
            SwitchListTile(
              title: const Text('Scouting Leader'),
              subtitle: const Text('Enable scouting leader features'),
              value: _scoutingLeaderEnabled,
              onChanged: (value) async {
                await _saveSetting(_scoutingLeaderKey, value);
                setState(() => _scoutingLeaderEnabled = value);
                notifyScoutingLeaderChange(value);
              },
            ),
          ],
        ),

        // Experimental Section
        _buildSection(
          title: 'Experimental',
          icon: Icons.science,
          children: [
            ListTile(
              title: Row(
                children: [
                  const Text('Enable Bluetooth'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: const Text(
                      'Unstable',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: const Text('Enable Bluetooth tab and functionality'),
              trailing: Switch(
                value: _bluetoothEnabled,
                onChanged: (value) async {
                  await _saveSetting(_bluetoothEnabledKey, value);
                  setState(() => _bluetoothEnabled = value);
                  
                  // Show a snackbar to inform the user about restarting the app
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please restart the app for changes to take effect'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
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

  Future<void> _exportDebugLogs() async {
    // Implement debug log export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug logs exported')),
    );
  }

  Future<void> _resetTeamNumber() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Team Number'),
        content: const Text(
          'This will:\n'
          '• Clear all cached team data\n'
          '• Reset your team number\n'
          '• Clear all saved match data\n\n'
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Clear all related data from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_teamNumberKey);
        await prefs.remove('team_data');
        await prefs.remove('events_data');

        // Also reset the API page state if it exists
        await ApiPageState.globalKey.currentState?.resetTeamData();

        // Clear all match records
        await DatabaseHelper.instance.deleteAllRecords();

        // Remove team number from settings state
        setState(() {
          _teamNumber = null;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team number has been reset. Please set a new team number in the API page.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resetting data: $e'), backgroundColor: Colors.red),
          );
        }
      }
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

  Future<void> _toggleKeepScreenAwake(bool value) async {
    try {
      await _saveSetting(_keepScreenAwakeKey, value);
      await _applyScreenWakeLock(value);
      setState(() => _keepScreenAwake = value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${value ? 'enable' : 'disable'} screen wake lock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}