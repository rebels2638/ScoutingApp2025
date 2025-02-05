import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelemetryOverlay extends StatefulWidget {
  final List<String> telemetryData;
  final VoidCallback onClose;

  const TelemetryOverlay({
    Key? key,
    required this.telemetryData,
    required this.onClose,
  }) : super(key: key);

  @override
  State<TelemetryOverlay> createState() => _TelemetryOverlayState();
}

class _TelemetryOverlayState extends State<TelemetryOverlay> {
  Offset position = const Offset(16, 16);
  bool isMinimized = false;
  final ScrollController _scrollController = ScrollController();
  bool _userScrolled = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isAtBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent;
      if (isAtBottom && _userScrolled) {
        setState(() {
          _userScrolled = false;
        });
      } else if (!isAtBottom && !_userScrolled) {
        setState(() {
          _userScrolled = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(TelemetryOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.telemetryData.length > oldWidget.telemetryData.length && !_userScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: position.dx,
      bottom: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position = Offset(
              position.dx - details.delta.dx,
              position.dy - details.delta.dy,
            );
          });
        },
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 300,
            height: isMinimized ? 48 : 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.terminal,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Telemetry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isMinimized ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                        ),
                        tooltip: isMinimized ? 'Expand' : 'Minimize',
                        onPressed: () {
                          setState(() {
                            isMinimized = !isMinimized;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_all, size: 20),
                        tooltip: 'Copy all telemetry',
                        onPressed: () {
                          final text = widget.telemetryData.join('\n');
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All telemetry copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: widget.onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Close telemetry',
                      ),
                    ],
                  ),
                ),
                // Content
                if (!isMinimized)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: widget.telemetryData.isEmpty
                          ? const Center(
                              child: Text('No telemetry data available'),
                            )
                          : NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification is ScrollUpdateNotification) {
                                  _userScrolled = true;
                                } else if (notification is ScrollEndNotification) {
                                  if (notification.metrics.pixels >= notification.metrics.maxScrollExtent) {
                                    setState(() {
                                      _userScrolled = false;
                                    });
                                  }
                                }
                                return true;
                              },
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var entry in widget.telemetryData)
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.grey[900]
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: entry.contains('ERROR:') 
                                                ? Colors.red.withOpacity(0.5)
                                                : Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey[700]!
                                                    : Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: entry.contains('ERROR:') ? () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Row(
                                                        children: [
                                                          const Icon(Icons.error_outline, color: Colors.red),
                                                          const SizedBox(width: 8),
                                                          const Text('Error Details'),
                                                        ],
                                                      ),
                                                      content: SingleChildScrollView(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            SelectableText(
                                                              entry,
                                                              style: const TextStyle(
                                                                fontFamily: 'RobotoMono',
                                                                height: 1.5,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 16),
                                                            const Text(
                                                              'Debugging Tips:',
                                                              style: TextStyle(fontWeight: FontWeight.bold),
                                                            ),
                                                            const SizedBox(height: 8),
                                                            if (entry.contains("'List<dynamic>' is not a subtype of type 'Map<dynamic, dynamic>'"))
                                                              Row(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Expanded(
                                                                    child: const Text(
                                                                      '• Check that your data is in a Map format like:\n'
                                                                      '  {\n'
                                                                      '    "key1": "value1",\n'
                                                                      '    "key2": "value2"\n'
                                                                      '  }\n\n'
                                                                      '• Instead of a List format like:\n'
                                                                      '  ["value1", "value2"]',
                                                                      style: TextStyle(
                                                                        fontFamily: 'RobotoMono',
                                                                        fontSize: 12,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(Icons.copy, size: 16),
                                                                    padding: EdgeInsets.zero,
                                                                    constraints: const BoxConstraints(),
                                                                    onPressed: () {
                                                                      const tipText = 
                                                                        'Example Map format:\n'
                                                                        '{\n'
                                                                        '  "key1": "value1",\n'
                                                                        '  "key2": "value2"\n'
                                                                        '}\n\n'
                                                                        'Instead of List format:\n'
                                                                        '["value1", "value2"]';
                                                                      Clipboard.setData(ClipboardData(text: tipText));
                                                                      Navigator.pop(context);
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text('Debugging tips copied'),
                                                                          duration: Duration(seconds: 1),
                                                                        ),
                                                                      );
                                                                    },
                                                                    tooltip: 'Copy example format',
                                                                  ),
                                                                ],
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: const Text('Close'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                } : null,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    SelectableText(
                                                      entry,
                                                      style: TextStyle(
                                                        fontFamily: 'RobotoMono',
                                                        fontSize: 13,
                                                        height: 1.5,
                                                        color: entry.contains('ERROR:') 
                                                            ? Colors.red 
                                                            : Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.grey[200]
                                                                : Colors.grey[900],
                                                        fontWeight: entry.contains('ERROR:') 
                                                            ? FontWeight.bold 
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                    if (entry.contains('ERROR:'))
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 8),
                                                        child: Text(
                                                          'Tap for debugging tips',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                            fontStyle: FontStyle.italic,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 16),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: entry));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Entry copied'),
                                                    duration: Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                              tooltip: 'Copy entry',
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 