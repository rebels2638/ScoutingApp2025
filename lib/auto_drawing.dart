import 'package:flutter/material.dart';
import 'drawing_page.dart' as drawing;
import 'theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class AutoPath {
  final int matchNumber;
  final String matchType;
  final int teamNumber;
  final bool isRedAlliance;
  final List<Map<String, dynamic>> path;
  final String? imagePath;
  final DateTime timestamp;

  AutoPath({
    required this.matchNumber,
    required this.matchType,
    required this.teamNumber,
    required this.isRedAlliance,
    required this.path,
    this.imagePath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'matchNumber': matchNumber,
    'matchType': matchType,
    'teamNumber': teamNumber,
    'isRedAlliance': isRedAlliance,
    'path': path,
    'imagePath': imagePath,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AutoPath.fromJson(Map<String, dynamic> json) => AutoPath(
    matchNumber: json['matchNumber'] as int,
    matchType: json['matchType'] as String,
    teamNumber: json['teamNumber'] as int,
    isRedAlliance: json['isRedAlliance'] as bool,
    path: (json['path'] as List).cast<Map<String, dynamic>>(),
    imagePath: json['imagePath'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class AutoDrawingPage extends StatefulWidget {
  const AutoDrawingPage({Key? key}) : super(key: key);

  @override
  State<AutoDrawingPage> createState() => _AutoDrawingPageState();
}

class _AutoDrawingPageState extends State<AutoDrawingPage> {
  int _selectedIndex = 0;
  final _matchNumberController = TextEditingController();
  final _teamNumberController = TextEditingController();
  String _matchType = 'Qualification';
  bool _isRedAlliance = true;
  List<AutoPath> _paths = [];
  String? _filterTeam;
  
  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final pathsJson = prefs.getString('auto_paths');
    if (pathsJson != null) {
      final List<dynamic> decoded = jsonDecode(pathsJson);
      setState(() {
        _paths = decoded.map((e) => AutoPath.fromJson(e)).toList();
      });
    }
  }

  Future<void> _savePaths() async {
    final prefs = await SharedPreferences.getInstance();
    final pathsJson = jsonEncode(_paths.map((p) => p.toJson()).toList());
    await prefs.setString('auto_paths', pathsJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Auto Drawing'),
      ),
      body: _selectedIndex == 0 ? _buildDrawingSection() : _buildPathsSection(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.brush),
            label: 'Draw',
          ),
          NavigationDestination(
            icon: Icon(Icons.list),
            label: 'Paths',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingSection() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _matchNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Match Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _matchType,
                        decoration: const InputDecoration(
                          labelText: 'Match Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Qualification', 'Quarterfinal', 'Semifinal', 'Final']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _matchType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _teamNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Team Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'Alliance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SegmentedButton<bool>(
                            segments: [
                              ButtonSegment<bool>(
                                value: true,
                                label: Text(
                                  'Red',
                                  style: TextStyle(
                                    color: _isRedAlliance 
                                        ? Colors.white 
                                        : AppColors.redAlliance,
                                  ),
                                ),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                label: Text(
                                  'Blue',
                                  style: TextStyle(
                                    color: !_isRedAlliance 
                                        ? Colors.white 
                                        : AppColors.blueAlliance,
                                  ),
                                ),
                              ),
                            ],
                            selected: {_isRedAlliance},
                            onSelectionChanged: (Set<bool> selected) {
                              setState(() {
                                _isRedAlliance = selected.first;
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return _isRedAlliance 
                                        ? AppColors.redAlliance 
                                        : AppColors.blueAlliance;
                                  }
                                  return Colors.transparent;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (_matchNumberController.text.isEmpty ||
                          _teamNumberController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                          ),
                        );
                        return;
                      }

                      final result = await Navigator.push<List<Map<String, dynamic>>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => drawing.DrawingPage(
                            isRedAlliance: _isRedAlliance,
                          ),
                        ),
                      );

                      if (result != null && mounted) {
                        final newPath = AutoPath(
                          matchNumber: int.parse(_matchNumberController.text),
                          matchType: _matchType,
                          teamNumber: int.parse(_teamNumberController.text),
                          isRedAlliance: _isRedAlliance,
                          path: result,
                          imagePath: result.firstWhere(
                            (element) => element['imagePath'] != null,
                            orElse: () => {'imagePath': null},
                          )['imagePath'] as String?,
                        );

                        setState(() {
                          _paths.add(newPath);
                        });
                        await _savePaths();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Auto path saved successfully'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.brush),
                    label: const Text('Draw Auto Path'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPathsSection() {
    final filteredPaths = _filterTeam != null && _filterTeam!.isNotEmpty
        ? _paths.where((p) => p.teamNumber.toString().contains(_filterTeam!)).toList()
        : _paths;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Filter by Team Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _filterTeam = value.isEmpty ? null : value;
                      });
                    },
                  ),
                ),
                if (_filterTeam != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _filterTeam = null;
                      });
                    },
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: _paths.isEmpty ? null : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete All Paths?'),
                        content: const Text(
                          'Are you sure you want to delete all auto paths? This cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              setState(() {
                                _paths.clear();
                              });
                              await _savePaths();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('All paths deleted'),
                                  ),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete All'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: filteredPaths.isEmpty
              ? Center(
                  child: Text(
                    _filterTeam != null
                        ? 'No paths found for team $_filterTeam'
                        : 'No auto paths recorded yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredPaths.length,
                  itemBuilder: (context, index) {
                    final path = filteredPaths[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => drawing.DrawingPage(
                                isRedAlliance: path.isRedAlliance,
                                initialDrawing: path.path,
                                readOnly: true,
                                imagePath: path.imagePath,
                                useDefaultImage: true,
                              ),
                            ),
                          );
                        },
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Auto Path?'),
                              content: Text(
                                'Are you sure you want to delete the auto path for Team ${path.teamNumber} (${path.matchType} Match ${path.matchNumber})?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    setState(() {
                                      _paths.remove(path);
                                    });
                                    await _savePaths();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Path deleted'),
                                        ),
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: path.isRedAlliance
                                          ? AppColors.redAlliance.withOpacity(0.1)
                                          : AppColors.blueAlliance.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Force 16:9 aspect ratio
                                        final width = constraints.maxWidth;
                                        final height = width * (9/16);
                                        return SizedBox(
                                          width: width,
                                          height: height,
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: SizedBox(
                                              width: width,
                                              height: height,
                                              child: drawing.DrawingPage(
                                                isRedAlliance: path.isRedAlliance,
                                                initialDrawing: path.path,
                                                readOnly: true,
                                                imagePath: path.imagePath,
                                                hideControls: true,
                                                useDefaultImage: true,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: path.isRedAlliance
                                            ? AppColors.redAlliance
                                            : AppColors.blueAlliance,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        path.isRedAlliance ? 'Red' : 'Blue',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Team ${path.teamNumber}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${path.matchType} Match ${path.matchNumber}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _matchNumberController.dispose();
    _teamNumberController.dispose();
    super.dispose();
  }
} 