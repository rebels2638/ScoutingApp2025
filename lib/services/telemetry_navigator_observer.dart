import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'telemetry_service.dart';

class TelemetryNavigatorObserver extends NavigatorObserver {
  final TelemetryService _telemetry = TelemetryService();
  Route<dynamic>? _currentRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _currentRoute = route;
    _logNavigation(route, previousRoute: previousRoute, action: 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _currentRoute = previousRoute;
    _logNavigation(previousRoute, previousRoute: route, action: 'pop');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _currentRoute = newRoute;
    _logNavigation(newRoute, previousRoute: oldRoute, action: 'replace');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _currentRoute = previousRoute;
    _logNavigation(previousRoute, previousRoute: route, action: 'remove');
  }

  void _logNavigation(Route<dynamic>? route, {
    Route<dynamic>? previousRoute,
    required String action,
  }) {
    final routeName = _getRouteName(route);
    final previousRouteName = _getRouteName(previousRoute);
    
    if (routeName != null) {
      final metadata = {
        'action': action,
        if (route is PageRoute) 'isModal': route.fullscreenDialog,
      };

      if (route is PageRoute) {
        metadata['transitionDuration'] = route.transitionDuration.inMilliseconds;
      }

      _telemetry.logNavigation(
        routeName,
        previousRoute: previousRouteName,
        metadata: metadata,
        parameters: _getRouteArguments(route),
      );
    }
  }

  String? _getRouteName(Route<dynamic>? route) {
    if (route == null) return null;
    return route.settings.name ?? route.runtimeType.toString();
  }

  Map<String, dynamic>? _getRouteArguments(Route<dynamic>? route) {
    if (route == null) return null;
    final args = route.settings.arguments;
    if (args == null) return null;
    if (args is Map<String, dynamic>) return args;
    return {'arguments': args.toString()};
  }

  Route<dynamic>? get currentRoute => _currentRoute;
} 