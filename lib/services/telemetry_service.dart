import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Stream<TelemetryEvent> get eventStream => _eventController.stream;
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  static const String _devModeKey = 'dev_mode_enabled';
  static const String _telemetryKey = 'telemetry_enabled';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_telemetryKey) ?? false;
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
  }

  void dispose() {
    _eventController.close();
  }
} 