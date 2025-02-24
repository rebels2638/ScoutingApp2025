import 'package:flutter/widgets.dart';
import '../services/telemetry_service.dart';

mixin TelemetryMixin<T extends StatefulWidget> on State<T> {
  final TelemetryService _telemetry = TelemetryService();
  String get screenName;
  
  @override
  void initState() {
    super.initState();
    _telemetry.logLifecycle('Page Mounted', screen: screenName);
  }

  @override
  void dispose() {
    _telemetry.logLifecycle('Page Disposed', screen: screenName);
    super.dispose();
  }

  void logAction(String message, [dynamic data, Map<String, dynamic>? metadata]) {
    _telemetry.logAction(message, data, screenName, metadata);
  }

  void logStateChange(String message, [dynamic data, Map<String, dynamic>? metadata]) {
    _telemetry.logStateChange(message, data, screenName, metadata);
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata]) {
    _telemetry.logError(message, error, stackTrace, screenName, metadata);
  }

  void logInfo(String message, [dynamic data, Map<String, dynamic>? metadata]) {
    _telemetry.logInfo(message, data, screenName, metadata);
  }

  void startPerformanceMarker(String markerId) {
    _telemetry.startPerformanceMarker('${screenName}_$markerId');
  }

  void endPerformanceMarker(String markerId, {String? description, Map<String, dynamic>? metadata}) {
    _telemetry.endPerformanceMarker('${screenName}_$markerId',
      description: description,
      metadata: {...?metadata, 'screen': screenName},
    );
  }
} 