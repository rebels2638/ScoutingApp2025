import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../services/telemetry_service.dart';

class TelemetryHook {
  final void Function(String message, {dynamic data, Map<String, dynamic>? metadata}) logAction;
  final void Function(String message, {dynamic data, Map<String, dynamic>? metadata}) logStateChange;
  final void Function(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) logError;
  final void Function(String message, {dynamic data, Map<String, dynamic>? metadata}) logInfo;
  final void Function(String message, {required Duration duration, Map<String, dynamic>? metadata}) logPerformance;
  final void Function(String message, {Map<String, dynamic>? metadata, dynamic data}) logLifecycle;
  final void Function() startPageView;
  final void Function() endPageView;
  final void Function(String markerId) startPerformanceMarker;
  final void Function(String markerId, {String? description, Map<String, dynamic>? metadata}) endPerformanceMarker;

  const TelemetryHook({
    required this.logAction,
    required this.logStateChange,
    required this.logError,
    required this.logInfo,
    required this.logPerformance,
    required this.logLifecycle,
    required this.startPageView,
    required this.endPageView,
    required this.startPerformanceMarker,
    required this.endPerformanceMarker,
  });
}

TelemetryHook useTelemetry(String screenName) {
  final telemetry = TelemetryService();
  final mounted = useRef(true);

  useEffect(() {
    mounted.value = true;
    telemetry.logLifecycle('Page Mounted', screen: screenName);
    
    return () {
      mounted.value = false;
      telemetry.logLifecycle('Page Disposed', screen: screenName);
    };
  }, []);

  return TelemetryHook(
    logAction: (message, {data, metadata}) {
      if (mounted.value) {
        telemetry.logAction(message, data, screenName, metadata);
      }
    },
    logStateChange: (message, {data, metadata}) {
      if (mounted.value) {
        telemetry.logStateChange(message, data, screenName, metadata);
      }
    },
    logError: (message, {error, stackTrace, metadata}) {
      if (mounted.value) {
        telemetry.logError(message, error, stackTrace, screenName, metadata);
      }
    },
    logInfo: (message, {data, metadata}) {
      if (mounted.value) {
        telemetry.logInfo(message, data, screenName, metadata);
      }
    },
    logPerformance: (message, {required duration, metadata}) {
      if (mounted.value) {
        telemetry.logPerformance(
          message,
          duration: duration,
          screen: screenName,
          metadata: metadata,
        );
      }
    },
    logLifecycle: (message, {metadata, data}) {
      if (mounted.value) {
        telemetry.logLifecycle(
          message,
          screen: screenName,
          metadata: metadata,
          data: data,
        );
      }
    },
    startPageView: () {
      if (mounted.value) {
        telemetry.logNavigation(screenName);
        telemetry.startPerformanceMarker('${screenName}_view_duration');
      }
    },
    endPageView: () {
      if (mounted.value) {
        telemetry.endPerformanceMarker('${screenName}_view_duration', 
          description: 'Page view duration for $screenName');
      }
    },
    startPerformanceMarker: (markerId) {
      if (mounted.value) {
        telemetry.startPerformanceMarker('${screenName}_$markerId');
      }
    },
    endPerformanceMarker: (markerId, {description, metadata}) {
      if (mounted.value) {
        telemetry.endPerformanceMarker('${screenName}_$markerId',
          description: description,
          metadata: {...?metadata, 'screen': screenName});
      }
    },
  );
} 