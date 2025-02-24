import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'drawing_page.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:math' show min;
import 'dart:async' show Completer;

class AutoPathPhotoPage extends StatefulWidget {
  final bool isRedAlliance;

  const AutoPathPhotoPage({
    Key? key,
    required this.isRedAlliance,
  }) : super(key: key);

  @override
  _AutoPathPhotoPageState createState() => _AutoPathPhotoPageState();
}

class _AutoPathPhotoPageState extends State<AutoPathPhotoPage> {
  File? _image;
  final _drawingKey = GlobalKey();
  List<DrawingLine> _lines = [];
  Color _currentColor = Colors.blue;
  double _currentWidth = 5.0;

  @override
  void initState() {
    super.initState();
    _takePhoto();
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
      
      // Navigate to DrawingPage immediately after taking photo
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DrawingPage(
              isRedAlliance: widget.isRedAlliance,
              imagePath: photo.path,
              useDefaultImage: false,  // Don't use default image
            ),
          ),
        );
        
        if (result != null) {
          // Make sure each line in the path has the image path
          final pathData = (result as List<Map<String, dynamic>>).map((line) => {
            ...line,
            'imagePath': photo.path,
          }).toList();
          // Pop directly with the path data
          Navigator.pop(context, pathData);
        } else {
          // If drawing was cancelled, also pop this page
          Navigator.pop(context);
        }
      }
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Over Photo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveDrawing,
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _drawingKey,
        child: Stack(
          children: [
            if (_image != null)
              Positioned.fill(
                child: Image.file(
                  _image!,
                  fit: BoxFit.contain,
                ),
              ),
            Positioned.fill(
              child: CustomPaint(
                size: Size.infinite,
                painter: DrawingPainter(
                  lines: _lines,
                  currentColor: _currentColor,
                  strokeWidth: _currentWidth,
                ),
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
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
              onPressed: _lines.isEmpty ? null : () {
                setState(() {
                  _lines.removeLast();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _lines.isEmpty ? null : () {
                setState(() {
                  _lines.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);
    
    // Get the image size and container size
    final imageSize = _getImageSize();
    final containerSize = box.size;
    
    // Map the point to the image coordinates
    final mappedPoint = _mapPointToImage(point, containerSize, imageSize);
    
    setState(() {
      _lines.add(
        DrawingLine(
          points: [mappedPoint],
          color: _currentColor,
          strokeWidth: _currentWidth,
        ),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);
    
    // Get the image size and container size
    final imageSize = _getImageSize();
    final containerSize = box.size;
    
    // Map the point to the image coordinates
    final mappedPoint = _mapPointToImage(point, containerSize, imageSize);
    
    setState(() {
      _lines.last.points.add(mappedPoint);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Path is complete
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            onColorChanged: (color) {
              setState(() {
                _currentColor = color;
              });
              Navigator.pop(context);
            },
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
        content: Slider(
          value: _currentWidth,
          min: 1,
          max: 20,
          onChanged: (value) {
            setState(() {
              _currentWidth = value;
            });
          },
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

  Future<void> _saveDrawing() async {
    try {
      // Convert the drawing to the format expected by the app
      final pathData = _lines.map((line) => {
        'points': line.points.map((point) => {
          'x': point.dx,
          'y': point.dy,
        }).toList(),
        'color': line.color.value,
        'strokeWidth': line.strokeWidth,
        'imagePath': _image?.path,  // Add the image path
      }).toList();

      Navigator.pop(context, pathData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving drawing: $e')),
      );
    }
  }

  Size _getImageSize() {
    if (_image == null) return Size.zero;
    
    // Get screen size and use it to estimate image size
    final screen = MediaQuery.of(context).size;
    
    // Use a 4:3 aspect ratio if in portrait, 16:9 if in landscape
    final isPortrait = screen.height > screen.width;
    if (isPortrait) {
      return Size(screen.width, screen.width * 4/3);
    } else {
      return Size(screen.width, screen.width * 9/16);
    }
  }

  Offset _mapPointToImage(Offset point, Size containerSize, Size imageSize) {
    // Calculate the scaling factors
    final scale = min(
      containerSize.width / imageSize.width,
      containerSize.height / imageSize.height,
    );
    
    // Calculate the image's displayed size
    final displayedWidth = imageSize.width * scale;
    final displayedHeight = imageSize.height * scale;
    
    // Calculate the offset to center the image
    final dx = (containerSize.width - displayedWidth) / 2;
    final dy = (containerSize.height - displayedHeight) / 2;
    
    // Adjust the point to account for the image's actual position
    final adjustedX = point.dx - dx;
    final adjustedY = point.dy - dy;
    
    // Convert to image coordinates
    final imageX = (adjustedX * imageSize.width) / displayedWidth;
    final imageY = (adjustedY * imageSize.height) / displayedHeight;
    
    return Offset(
      imageX.clamp(0.0, imageSize.width),
      imageY.clamp(0.0, imageSize.height),
    );
  }
}

class ColorPicker extends StatelessWidget {
  final Function(Color) onColorChanged;

  const ColorPicker({
    Key? key,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
        onTap: () => onColorChanged(color),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      )).toList(),
    );
  }
} 