import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

enum TelemetryType {
  error,
  action,
  stateChange,
  info,
  performance,
  navigation,
  lifecycle
}

class TelemetryEvent {
  final DateTime timestamp;
  final TelemetryType type;
  final String message;
  final Map<String, dynamic>? metadata;
  final dynamic data;
  final String? screen;
  final Duration? duration;

  TelemetryEvent({
    required this.type,
    required this.message,
    this.metadata,
    this.data,
    this.screen,
    this.duration,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'message': message,
    if (metadata != null) 'metadata': metadata,
    if (data != null) 'data': data,
    if (screen != null) 'screen': screen,
    if (duration != null) 'duration': duration?.inMilliseconds,
  };

  @override
  String toString() {
    final parts = <String>[
      '[${timestamp.toIso8601String()}]',
      type.name.toUpperCase(),
      if (screen != null) '[$screen]',
      message,
    ];

    if (duration != null) {
      parts.add('(${duration!.inMilliseconds}ms)');
    }

    if (metadata != null) {
      parts.add('metadata: $metadata');
    }

    if (data != null) {
      parts.add('data: $data');
    }

    return parts.join(' ');
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

  // Performance tracking
  final Map<String, DateTime> _performanceMarkers = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_telemetryKey) ?? false;
    final devMode = prefs.getBool(_devModeKey) ?? false;
    _devModeController.add(devMode);
  }

  void startPerformanceMarker(String markerId) {
    _performanceMarkers[markerId] = DateTime.now();
  }

  void endPerformanceMarker(String markerId, {String? description, Map<String, dynamic>? metadata}) {
    final startTime = _performanceMarkers.remove(markerId);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      logPerformance(
        description ?? 'Performance marker: $markerId',
        duration: duration,
        metadata: {...?metadata, 'markerId': markerId},
      );
    }
  }

  void logPerformance(String message, {
    required Duration duration,
    Map<String, dynamic>? metadata,
    String? screen,
  }) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.performance,
      message: message,
      duration: duration,
      metadata: metadata,
      screen: screen,
    ));
  }

  void logNavigation(String route, {
    String? previousRoute,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.navigation,
      message: 'Navigation: $route',
      metadata: {
        ...?metadata,
        if (previousRoute != null) 'previousRoute': previousRoute,
        if (parameters != null) 'parameters': parameters,
      },
      screen: route,
    ));
  }

  void logLifecycle(String message, {
    required String screen,
    Map<String, dynamic>? metadata,
    dynamic data,
  }) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.lifecycle,
      message: message,
      metadata: metadata,
      data: data,
      screen: screen,
    ));
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace, String? screen, Map<String, dynamic>? metadata]) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.error,
      message: message,
      metadata: {
        ...?metadata,
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      },
      data: error?.toString(),
      screen: screen,
    ));
  }

  void logAction(String message, [dynamic data, String? screen, Map<String, dynamic>? metadata]) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.action,
      message: message,
      metadata: metadata,
      data: data,
      screen: screen,
    ));
  }

  void logStateChange(String message, [dynamic data, String? screen, Map<String, dynamic>? metadata]) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.stateChange,
      message: message,
      metadata: metadata,
      data: data,
      screen: screen,
    ));
  }

  void logInfo(String message, [dynamic data, String? screen, Map<String, dynamic>? metadata]) {
    if (!_isEnabled) return;
    _eventController.add(TelemetryEvent(
      type: TelemetryType.info,
      message: message,
      metadata: metadata,
      data: data,
      screen: screen,
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