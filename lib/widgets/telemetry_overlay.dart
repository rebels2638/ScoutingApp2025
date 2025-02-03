import 'package:flutter/material.dart';
import '../services/telemetry_service.dart';

class TelemetryOverlay extends StatefulWidget {
  final Widget child;
  final bool isVisible;
  final Function(bool)? onVisibilityChanged;

  const TelemetryOverlay({
    required this.child,
    required this.isVisible,
    this.onVisibilityChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<TelemetryOverlay> createState() => _TelemetryOverlayState();
}

class _TelemetryOverlayState extends State<TelemetryOverlay> {
  final List<TelemetryEvent> _events = [];
  final ScrollController _scrollController = ScrollController();

  void _clearLogs() {
    setState(() {
      _events.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    TelemetryService().eventStream.listen((event) {
      setState(() {
        _events.insert(0, event);
        if (_events.length > 100) {
          _events.removeLast();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (widget.isVisible)
            Positioned(
              top: 100,
              left: 20,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Telemetry',
                              style: TextStyle(color: Colors.white),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                _clearLogs();
                                widget.onVisibilityChanged?.call(false);
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                event.toString(),
                                style: TextStyle(
                                  color: _getEventColor(event.type),
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getEventColor(TelemetryType type) {
    switch (type) {
      case TelemetryType.error:
        return Colors.red;
      case TelemetryType.action:
        return Colors.green;
      case TelemetryType.stateChange:
        return Colors.orange;
      case TelemetryType.info:
        return Colors.blue;
    }
  }
} 