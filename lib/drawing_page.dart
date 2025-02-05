import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

// Add a class to store line properties
class DrawingLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  Map<String, dynamic> toCompressedJson() {
    // Reduce precision of coordinates to 1 decimal place and use shorter key names
    return {
      'p': points.map((p) => {
        'x': (p.dx * 10).round() / 10,
        'y': (p.dy * 10).round() / 10,
      }).toList(),
      'c': color.value,
      'w': (strokeWidth * 10).round() / 10,
    };
  }

  static DrawingLine fromJson(Map<String, dynamic> json) {
    return DrawingLine(
      points: (json['points'] as List).map((p) {
        final point = p as Map<String, dynamic>;
        return Offset(
          (point['x'] as num).toDouble(),
          (point['y'] as num).toDouble(),
        );
      }).toList(),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
    );
  }

  static DrawingLine fromCompressedJson(Map<String, dynamic> json) {
    return DrawingLine(
      points: (json['p'] as List).map((p) {
        final point = p as Map<String, dynamic>;
        return Offset(
          (point['x'] as num).toDouble(),
          (point['y'] as num).toDouble(),
        );
      }).toList(),
      color: Color(json['c'] as int),
      strokeWidth: (json['w'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }
}

class DrawingPage extends StatefulWidget {
  final bool isRedAlliance;
  final List<Map<String, dynamic>>? initialDrawing;
  final bool readOnly;

  const DrawingPage({
    Key? key,
    required this.isRedAlliance,
    this.initialDrawing,
    this.readOnly = false,
  }) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  List<DrawingLine> lines = [];
  List<DrawingLine> redoHistory = [];
  Color currentColor = Colors.black;
  bool isErasing = false;
  double strokeWidth = 5.0;
  List<Offset>? currentLine;

  @override
  void initState() {
    super.initState();
    currentColor = widget.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance;
    _initializeDrawing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auto Path Drawing'),
        actions: widget.readOnly ? [] : [
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: lines.isEmpty ? null : undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: Icon(Icons.redo),
            onPressed: redoHistory.isEmpty ? null : redo,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: Icon(isErasing ? Icons.edit : Icons.auto_fix_high),
            onPressed: () {
              setState(() {
                isErasing = !isErasing;
              });
            },
            tooltip: isErasing ? 'Draw Mode' : 'Erase Mode',
          ),
          if (!widget.readOnly)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                Navigator.pop(context, lines.map((line) => line.toMap()).toList());
              },
              tooltip: 'Save Drawing',
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: CustomPaint(
              painter: DrawingPainter(
                lines: lines,
                currentColor: currentColor,
                strokeWidth: strokeWidth,
              ),
              child: GestureDetector(
                onPanStart: widget.readOnly ? null : _onPanStart,
                onPanUpdate: widget.readOnly ? null : _onPanUpdate,
                onPanEnd: widget.readOnly ? null : _onPanEnd,
              ),
            ),
          ),
          if (!widget.readOnly)
            Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Stroke Width'),
                      Slider(
                        value: strokeWidth,
                        min: 1.0,
                        max: 20.0,
                        onChanged: (value) {
                          setState(() {
                            strokeWidth = value;
                          });
                        },
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

  void undo() {
    if (lines.isNotEmpty) {
      setState(() {
        redoHistory.add(lines.removeLast());
      });
    }
  }

  void redo() {
    if (redoHistory.isNotEmpty) {
      setState(() {
        lines.add(redoHistory.removeLast());
      });
    }
  }

  void _initializeDrawing() {
    try {
      lines = widget.initialDrawing?.map((map) {
        final pointsList = (map['points'] as List).map((p) {
          final point = p as Map<String, dynamic>;
          return Offset(
            (point['x'] as num).toDouble(),
            (point['y'] as num).toDouble(),
          );
        }).toList();
        
        return DrawingLine(
          points: pointsList,
          color: Color(map['color'] as int),
          strokeWidth: (map['strokeWidth'] as num).toDouble(),
        );
      }).toList() ?? [];
    } catch (e) {
      print('Error initializing drawing: $e');  // Debug print
      lines = [];
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      currentLine = [details.localPosition];
      if (!isErasing) {
        lines.add(DrawingLine(
          points: currentLine!,
          color: currentColor,
          strokeWidth: strokeWidth,
        ));
        redoHistory.clear();
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (isErasing) {
        lines.removeWhere((line) {
          return line.points.any((point) =>
              (point - details.localPosition).distance < 20.0);
        });
      } else if (currentLine != null) {
        currentLine!.add(details.localPosition);
        // Update the points of the last line
        lines.last = DrawingLine(
          points: currentLine!,
          color: currentColor,
          strokeWidth: strokeWidth,
        );
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    currentLine = null;
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingLine> lines;
  final Color currentColor;
  final double strokeWidth;

  DrawingPainter({
    required this.lines,
    required this.currentColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.strokeWidth
        ..strokeCap = StrokeCap.round;

      if (line.points.length < 2) continue;
      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
} 