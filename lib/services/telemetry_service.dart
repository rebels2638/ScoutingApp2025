import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

enum TelemetryType {
  error,
  action,
  stateChange,
  info
}

class TelemetryEvent {
  final DateTime timestamp;
  final TelemetryType type;
  final String message;
  final dynamic data;

  TelemetryEvent({
    required this.type,
    required this.message,
    this.data,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return '[${timestamp.toIso8601String()}] ${type.name.toUpperCase()}: $message ${data != null ? '- $data' : ''}';
  }
}

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  final _eventController = StreamController<TelemetryEvent>.broadcast();
  final _devModeController = StreamController<bool>.broadcast();
  
  Stream<TelemetryEvent> get eventStream => _eventController.stream;
  Stream<bool> get devModeStream => _devModeController.stream;
  
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  static const String _devModeKey = 'dev_mode_enabled';
  static const String _telemetryKey = 'telemetry_enabled';


  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_telemetryKey) ?? false;
    final devMode = prefs.getBool(_devModeKey) ?? false;
    _devModeController.add(devMode);
  }

  void logError(String message, [dynamic error]) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.error,
      message: message,
      data: error?.toString(),
    ));
  }

  void logAction(String message, [dynamic data]) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.action,
      message: message,
      data: data,
    ));
  }

  void logStateChange(String message, [dynamic data]) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.stateChange,
      message: message,
      data: data,
    ));
  }

  void logInfo(String message, [dynamic data]) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.info,
      message: message,
      data: data,
    ));
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_telemetryKey, enabled);
  }

  static Future<bool> isDevModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_devModeKey) ?? false;
  }

  static Future<void> setDevModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devModeKey, enabled);
    TelemetryService()._devModeController.add(enabled);
  }

  void dispose() {
    _eventController.close();
    _devModeController.close();
  }
}

class TelemetryDialog extends StatelessWidget {
  final List<String> telemetryData;
  final String title;

  const TelemetryDialog({
    Key? key,
    required this.telemetryData,
    this.title = 'Telemetry',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_all),
                      tooltip: 'Copy all',
                      onPressed: () {
                        final text = telemetryData.join('\n');
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    telemetryData.join('\n'),
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 13,
                      height: 1.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[200]
                          : Colors.grey[900],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showTelemetryDialog(BuildContext context, List<String> telemetryData, {String? title}) {
  showDialog(
    context: context,
    builder: (context) => TelemetryDialog(
      telemetryData: telemetryData,
      title: title ?? 'Telemetry',
    ),
  );
} 