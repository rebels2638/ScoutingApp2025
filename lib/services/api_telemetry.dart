import '../services/telemetry_service.dart';

class ApiTelemetry {
  final TelemetryService _telemetry = TelemetryService();
  final String screenName;

  ApiTelemetry(this.screenName);

  void logApiRequest(String endpoint, {
    Map<String, dynamic>? parameters,
    Duration? duration,
  }) {
    _telemetry.logInfo(
      'API Request',
      {
        'endpoint': endpoint,
        if (parameters != null) 'parameters': parameters,
      },
      screenName,
    );

    if (duration != null) {
      _telemetry.logPerformance(
        'API Request Duration',
        duration: duration,
        screen: screenName,
        metadata: {
          'endpoint': endpoint,
          if (parameters != null) 'parameters': parameters,
        },
      );
    }
  }

  void logApiResponse(String endpoint, {
    required bool success,
    dynamic data,
    String? error,
    Duration? duration,
  }) {
    if (success) {
      _telemetry.logInfo(
        'API Response Success',
        {
          'endpoint': endpoint,
          'responseData': data,
        },
        screenName,
      );
    } else {
      _telemetry.logError(
        'API Response Error',
        error,
        null,
        screenName,
        {
          'endpoint': endpoint,
        },
      );
    }

    if (duration != null) {
      _telemetry.logPerformance(
        'API Response Processing',
        duration: duration,
        screen: screenName,
        metadata: {
          'endpoint': endpoint,
          'success': success,
        },
      );
    }
  }

  void logCompetitionDataFetch({
    required String competitionId,
    required bool success,
    int? matchCount,
    String? error,
  }) {
    if (success) {
      _telemetry.logInfo(
        'Competition Data Fetched',
        {
          'competitionId': competitionId,
          'matchCount': matchCount,
        },
        screenName,
      );
    } else {
      _telemetry.logError(
        'Competition Data Fetch Failed',
        error,
        null,
        screenName,
        {
          'competitionId': competitionId,
        },
      );
    }
  }

  void logTeamDataFetch({
    required int teamNumber,
    required bool success,
    Map<String, dynamic>? data,
    String? error,
  }) {
    if (success) {
      _telemetry.logInfo(
        'Team Data Fetched',
        {
          'teamNumber': teamNumber,
          'data': data,
        },
        screenName,
      );
    } else {
      _telemetry.logError(
        'Team Data Fetch Failed',
        error,
        null,
        screenName,
        {
          'teamNumber': teamNumber,
        },
      );
    }
  }

  void logMatchDataFetch({
    required String matchId,
    required bool success,
    Map<String, dynamic>? data,
    String? error,
  }) {
    if (success) {
      _telemetry.logInfo(
        'Match Data Fetched',
        {
          'matchId': matchId,
          'data': data,
        },
        screenName,
      );
    } else {
      _telemetry.logError(
        'Match Data Fetch Failed',
        error,
        null,
        screenName,
        {
          'matchId': matchId,
        },
      );
    }
  }

  void logDataSync({
    required bool success,
    int? itemsSynced,
    String? error,
  }) {
    if (success) {
      _telemetry.logInfo(
        'Data Sync Completed',
        {
          'itemsSynced': itemsSynced,
        },
        screenName,
      );
    } else {
      _telemetry.logError(
        'Data Sync Failed',
        error,
        null,
        screenName,
      );
    }
  }
} 