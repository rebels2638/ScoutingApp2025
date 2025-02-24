import 'package:flutter/material.dart';
import 'telemetry_overlay.dart';

class TelemetryContainer extends StatefulWidget {
  final List<String> telemetryData;
  final VoidCallback onClose;

  const TelemetryContainer({
    Key? key,
    required this.telemetryData,
    required this.onClose,
  }) : super(key: key);

  @override
  State<TelemetryContainer> createState() => _TelemetryContainerState();
}

class _TelemetryContainerState extends State<TelemetryContainer> {
  Offset position = const Offset(16, 16);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: position.dx,
      bottom: position.dy,
      child: TelemetryOverlay(
        telemetryData: widget.telemetryData,
        onClose: widget.onClose,
        onDrag: (delta) {
          final size = MediaQuery.of(context).size;
          setState(() {
            position = Offset(
              (position.dx - delta.dx).clamp(0.0, size.width - 300),
              (position.dy - delta.dy).clamp(0.0, size.height - 400),
            );
          });
        },
      ),
    );
  }
} 