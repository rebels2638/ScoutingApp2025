import 'package:flutter/material.dart';
import '../services/telemetry_service.dart';

class DrawingTelemetry {
  final TelemetryService _telemetry = TelemetryService();
  final String screenName;

  DrawingTelemetry(this.screenName);

  void logDrawStart(Offset position) {
    _telemetry.logAction(
      'Drawing started',
      {'x': position.dx, 'y': position.dy},
      screenName,
    );
  }

  void logDrawEnd(Offset position, {int pointCount = 0}) {
    _telemetry.logAction(
      'Drawing ended',
      {
        'x': position.dx,
        'y': position.dy,
        'pointCount': pointCount,
      },
      screenName,
    );
  }

  void logToolChange(String tool) {
    _telemetry.logAction(
      'Drawing tool changed',
      tool,
      screenName,
    );
  }

  void logColorChange(Color color) {
    _telemetry.logAction(
      'Drawing color changed',
      '#${color.value.toRadixString(16)}',
      screenName,
    );
  }

  void logStrokeWidthChange(double width) {
    _telemetry.logAction(
      'Stroke width changed',
      width,
      screenName,
    );
  }

  void logClear() {
    _telemetry.logAction(
      'Drawing cleared',
      null,
      screenName,
    );
  }

  void logUndo() {
    _telemetry.logAction(
      'Drawing action undone',
      null,
      screenName,
    );
  }

  void logRedo() {
    _telemetry.logAction(
      'Drawing action redone',
      null,
      screenName,
    );
  }

  void logSave({required bool success, String? error}) {
    if (success) {
      _telemetry.logAction(
        'Drawing saved',
        null,
        screenName,
      );
    } else {
      _telemetry.logError(
        'Failed to save drawing',
        error,
        null,
        screenName,
      );
    }
  }

  void logLoad({required bool success, String? error}) {
    if (success) {
      _telemetry.logAction(
        'Drawing loaded',
        null,
        screenName,
      );
    } else {
      _telemetry.logError(
        'Failed to load drawing',
        error,
        null,
        screenName,
      );
    }
  }
} 