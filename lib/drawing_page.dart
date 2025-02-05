import 'package:flutter/material.dart';

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
}

class DrawingPage extends StatefulWidget {
  final bool isRedAlliance;
  final List<Map<String, dynamic>>? initialDrawing;
  final bool readOnly;

  const DrawingPage({
    super.key,
    required this.isRedAlliance,
    this.initialDrawing,
    this.readOnly = false,
  });

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  late List<DrawingLine> lines;
  List<DrawingLine> undoHistory = [];
  List<DrawingLine> redoHistory = [];
  List<Offset>? currentLine;
  bool isErasing = false;
  Color currentColor = Colors.blue;
  double strokeWidth = 3.0;

  @override
  void initState() {
    super.initState();
    currentColor = widget.isRedAlliance ? Colors.red : Colors.blue;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Path Drawing'),
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
          PopupMenuButton<Color>(
            icon: Icon(Icons.color_lens),
            tooltip: 'Change Color',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: Colors.red,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text('Red'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: Colors.blue,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 8),
                    Text('Blue'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: Colors.green,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Text('Green'),
                  ],
                ),
              ),
            ],
            onSelected: (Color color) {
              setState(() {
                currentColor = color;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                undoHistory.addAll(lines);
                lines.clear();
                redoHistory.clear();
              });
            },
            tooltip: 'Clear All',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveDrawing,
            tooltip: 'Save Drawing',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/field_image.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
          ),
          // Drawing Layer
          Positioned.fill(
            child: GestureDetector(
              onPanStart: widget.readOnly ? null : (details) {
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
              },
              onPanUpdate: widget.readOnly ? null : (details) {
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
              },
              onPanEnd: widget.readOnly ? null : (details) {
                currentLine = null;
              },
              child: CustomPaint(
                painter: DrawingPainter(lines: lines),
                size: Size.infinite,
              ),
            ),
          ),
          // Stroke Width Slider
          if (!widget.readOnly)
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.line_weight, color: Colors.white),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 150,
                      child: Slider(
                        value: strokeWidth,
                        min: 1.0,
                        max: 10.0,
                        onChanged: (value) {
                          setState(() {
                            strokeWidth = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Update save functionality
  void saveDrawing() {
    try {
      final drawingData = lines.map((line) => {
        'points': line.points.map((p) => {
          'x': p.dx,
          'y': p.dy,
        }).toList(),
        'color': line.color.value,
        'strokeWidth': line.strokeWidth,
      }).toList();
      
      // Debug print to see the data structure
      print('Drawing data before save: $drawingData');
      
      Navigator.pop(context, drawingData);
    } catch (e) {
      print('Error saving drawing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving drawing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingLine> lines;

  DrawingPainter({required this.lines});

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