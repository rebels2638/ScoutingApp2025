import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'dart:io';

// Add a class to store line properties
class DrawingLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final String? imagePath;

  DrawingLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'imagePath': imagePath,
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

  factory DrawingLine.fromJson(Map<String, dynamic> json) {
    final List<dynamic> pointsData = json['points'] as List;
    final List<Offset> points = pointsData.map((point) {
      return Offset(
        (point['x'] as num).toDouble(),
        (point['y'] as num).toDouble(),
      );
    }).toList();

    return DrawingLine(
      points: points,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      imagePath: json['imagePath'] as String?,
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
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'imagePath': imagePath,
    };
  }
}

class DrawingPage extends StatefulWidget {
  final bool isRedAlliance;
  final bool readOnly;
  final List<Map<String, dynamic>>? initialDrawing;
  final String? imagePath;
  final bool useDefaultImage;

  const DrawingPage({
    Key? key,
    required this.isRedAlliance,
    this.readOnly = false,
    this.initialDrawing,
    this.imagePath,
    this.useDefaultImage = true,
  }) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  late List<DrawingLine> lines;
  List<DrawingLine> redoHistory = [];
  Color currentColor = Colors.black;
  bool isErasing = false;
  double strokeWidth = 5.0;
  DrawingLine? currentLine;
  String? imagePath;

  @override
  void initState() {
    super.initState();
    currentColor = widget.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance;
    imagePath = widget.imagePath;
    
    // Initialize lines from either initialLines or initialDrawing
    if (widget.initialDrawing != null) {
      lines = widget.initialDrawing!.map((map) {
        final line = DrawingLine.fromJson(map);
        // If the line has an image path and we don't have one yet, use it
        if (imagePath == null && line.imagePath != null) {
          imagePath = line.imagePath;
        }
        return line;
      }).toList();
    } else {
      lines = [];
    }
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
                final pathData = lines.map((line) => {
                  ...line.toMap(),
                  'imagePath': imagePath,
                }).toList();
                Navigator.pop(context, pathData);
              },
              tooltip: 'Save Drawing',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background image logic
          Positioned.fill(
            child: imagePath != null && File(imagePath!).existsSync()
                ? Image.file(
                    File(imagePath!),
                    fit: BoxFit.contain,
                  )
                : widget.useDefaultImage
                    ? Image.asset(
                        'assets/field_image.png',
                        fit: BoxFit.contain,
                      )
                    : Container(),  // Empty container if no image should be shown
          ),
          // Drawing area
          Container(
            child: CustomPaint(
              painter: DrawingPainter(
                lines: lines,
                currentColor: currentColor,
                strokeWidth: strokeWidth,
              ),
              child: widget.readOnly
                  ? Container()
                  : GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.readOnly ? null : BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.color_lens),
              onPressed: _showColorPicker,
            ),
            IconButton(
              icon: const Icon(Icons.line_weight),
              onPressed: _showStrokeWidth,
            ),
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: lines.isEmpty ? null : () {
                setState(() {
                  lines.removeLast();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: lines.isEmpty ? null : () {
                setState(() {
                  lines.clear();
                });
              },
            ),
          ],
        ),
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

  void _onPanStart(DragStartDetails details) {
    currentLine = DrawingLine(
      points: [details.localPosition],
      color: currentColor,
      strokeWidth: strokeWidth,
      imagePath: imagePath,
    );
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (currentLine == null) return;
    
    setState(() {
      if (!isErasing) {
        currentLine!.points.add(details.localPosition);
        // Only update the last line if it's the current one
        if (lines.isNotEmpty && lines.last == currentLine) {
          lines.last = currentLine!;
        } else {
          lines.add(currentLine!);
        }
      } else {
        // Optimize erasing by using Rect.contains
        final erasePoint = details.localPosition;
        lines.removeWhere((line) {
          return line.points.any((point) =>
              (point - erasePoint).distance < 20.0);
        });
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (currentLine != null && currentLine!.points.length > 1) {
      redoHistory.clear();
    }
    currentLine = null;
    setState(() {});
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                  Colors.teal,
                  Colors.pink,
                ].map((color) => GestureDetector(
                  onTap: () {
                    setState(() {
                      currentColor = color;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStrokeWidth() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Stroke Width'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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