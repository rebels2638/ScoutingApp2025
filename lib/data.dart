import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'comparison.dart';
import 'team_analysis.dart';

class ScoutingRecord {
  final String timestamp;
  final int matchNumber;
  final String matchType;
  final int teamNumber;
  final bool isRedAlliance;
  
  // auto
  final String cageType;
  final bool coralPreloaded;
  final bool taxis;
  final int algaeRemoved;
  final String coralPlaced;
  final bool rankingPoint;
  final bool canPickupCoral;
  final bool canPickupAlgae;
  
  // teleop
  final int algaeScoredInNet;
  final bool coralRankingPoint;
  final int algaeProcessed;
  final int processedAlgaeScored;
  final int processorCycles;
  final bool coOpPoint;
  
  // endgame
  final bool returnedToBarge;
  final String cageHang;
  final bool bargeRankingPoint;
  
  // other
  final bool breakdown;
  final String comments;

  ScoutingRecord({
    required this.timestamp,
    required this.matchNumber,
    required this.matchType,
    required this.teamNumber,
    required this.isRedAlliance,
    required this.cageType,
    required this.coralPreloaded,
    required this.taxis,
    required this.algaeRemoved,
    required this.coralPlaced,
    required this.rankingPoint,
    required this.canPickupCoral,
    required this.canPickupAlgae,
    required this.algaeScoredInNet,
    required this.coralRankingPoint,
    required this.algaeProcessed,
    required this.processedAlgaeScored,
    required this.processorCycles,
    required this.coOpPoint,
    required this.returnedToBarge,
    required this.cageHang,
    required this.bargeRankingPoint,
    required this.breakdown,
    required this.comments,
  }) : assert(coralPreloaded != null),
       assert(taxis != null),
       assert(rankingPoint != null),
       assert(canPickupCoral != null),
       assert(canPickupAlgae != null),
       assert(coralRankingPoint != null),
       assert(coOpPoint != null),
       assert(returnedToBarge != null),
       assert(bargeRankingPoint != null),
       assert(breakdown != null);

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'matchNumber': matchNumber,
    'matchType': matchType,
    'teamNumber': teamNumber,
    'isRedAlliance': isRedAlliance,
    'cageType': cageType,
    'coralPreloaded': coralPreloaded,
    'taxis': taxis,
    'algaeRemoved': algaeRemoved,
    'coralPlaced': coralPlaced,
    'rankingPoint': rankingPoint,
    'canPickupCoral': canPickupCoral,
    'canPickupAlgae': canPickupAlgae,
    'algaeScoredInNet': algaeScoredInNet,
    'coralRankingPoint': coralRankingPoint,
    'algaeProcessed': algaeProcessed,
    'processedAlgaeScored': processedAlgaeScored,
    'processorCycles': processorCycles,
    'coOpPoint': coOpPoint,
    'returnedToBarge': returnedToBarge,
    'cageHang': cageHang,
    'bargeRankingPoint': bargeRankingPoint,
    'breakdown': breakdown,
    'comments': comments,
  };

  factory ScoutingRecord.fromJson(Map<String, dynamic> json) => ScoutingRecord(
    timestamp: json['timestamp'] ?? '',
    matchNumber: json['matchNumber'] ?? 0,
    matchType: json['matchType'] ?? 'Unset',
    teamNumber: json['teamNumber'] ?? 0,
    isRedAlliance: json['isRedAlliance'] ?? false,
    cageType: json['cageType'] ?? 'Shallow',
    coralPreloaded: json['coralPreloaded'] ?? false,
    taxis: json['taxis'] ?? false,
    algaeRemoved: json['algaeRemoved'] ?? 0,
    coralPlaced: json['coralPlaced'] ?? 'No',
    rankingPoint: json['rankingPoint'] ?? false,
    canPickupCoral: json['canPickupCoral'] ?? false,
    canPickupAlgae: json['canPickupAlgae'] ?? false,
    algaeScoredInNet: json['algaeScoredInNet'] ?? 0,
    coralRankingPoint: json['coralRankingPoint'] ?? false,
    algaeProcessed: json['algaeProcessed'] ?? 0,
    processedAlgaeScored: json['processedAlgaeScored'] ?? 0,
    processorCycles: json['processorCycles'] ?? 0,
    coOpPoint: json['coOpPoint'] ?? false,
    returnedToBarge: json['returnedToBarge'] ?? false,
    cageHang: json['cageHang'] ?? 'None',
    bargeRankingPoint: json['bargeRankingPoint'] ?? false,
    breakdown: json['breakdown'] ?? false,
    comments: json['comments'] ?? '',
  );
}

class DataManager {
  static const String _storageKey = 'scouting_records';
  
  static Future<void> saveRecord(ScoutingRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    records.add(record);
    await prefs.setString(_storageKey, jsonEncode(records.map((r) => r.toJson()).toList()));
  }
  
  static Future<List<ScoutingRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recordsJson = prefs.getString(_storageKey);
    if (recordsJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(recordsJson);
    return decoded.map((json) => ScoutingRecord.fromJson(json)).toList();
  }

  static Future<void> deleteRecord(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    records.removeAt(index);
    await prefs.setString(_storageKey, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  static Future<void> exportToJson() async {
    try {
      final records = await getRecords();
      if (records.isEmpty) {
        throw Exception('No records to export');
      }

      final jsonStr = jsonEncode(records.map((r) => r.toJson()).toList());
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Scouting Records',
        fileName: 'scouting_records.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (outputFile == null) {
        throw Exception('Export cancelled');
      }

      // ensure file ends with .json
      if (!outputFile.toLowerCase().endsWith('.json')) {
        outputFile += '.json';
      }

      await File(outputFile).writeAsString(jsonStr, flush: true);
    } catch (e) {
      throw Exception('Failed to export: ${e.toString()}');
    }
  }

  static Future<void> importFromJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      if (result.files.single.path == null) {
        throw Exception('Invalid file path');
      }

      final file = File(result.files.single.path!);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final jsonStr = await file.readAsString();
      if (jsonStr.isEmpty) {
        throw Exception('File is empty');
      }
      
      final List<dynamic> decoded = jsonDecode(jsonStr);
      if (decoded.isEmpty) {
        throw Exception('No records found in file');
      }

      final records = decoded.map((json) => ScoutingRecord.fromJson(json)).toList();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid JSON format');
      }
      throw Exception('Failed to import: ${e.toString()}');
    }
  }
}

class DataPage extends StatefulWidget {
  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List<ScoutingRecord> _records = [];
  List<ScoutingRecord> _selectedRecords = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await DataManager.getRecords();
    setState(() {
      _records = records;
      _selectedRecords.clear();
    });
  }

  void _toggleRecordSelection(ScoutingRecord record) {
    setState(() {
      if (_selectedRecords.contains(record)) {
        _selectedRecords.remove(record);
      } else {
        _selectedRecords.add(record);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900
                  : Colors.blue.shade50,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await DataManager.exportToJson();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Export successful')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? null 
                            : Colors.grey.shade200,
                        foregroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? null 
                            : Colors.black,
                      ),
                      icon: Icon(Icons.upload, color: Theme.of(context).brightness == Brightness.dark 
                          ? null 
                          : Colors.black),
                      label: Text('Export Data'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await DataManager.importFromJson();
                          _loadRecords();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Import successful')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? null 
                            : Colors.grey.shade200,
                        foregroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? null 
                            : Colors.black,
                      ),
                      icon: Icon(Icons.download, color: Theme.of(context).brightness == Brightness.dark 
                          ? null 
                          : Colors.black),
                      label: Text('Import Data'),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamAnalysisPage(allRecords: _records),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.analytics, color: Colors.white),
                      label: Text('Team Analysis'),
                    ),
                    if (_selectedRecords.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () {
                          Map<int, List<ScoutingRecord>> teamRecords = {};
                          for (var record in _selectedRecords) {
                            teamRecords.putIfAbsent(record.teamNumber, () => []).add(record);
                          }
                          
                          List<ScoutingRecord> orderedRecords = teamRecords.values.map((records) {
                            return records..sort((a, b) =>
                              (b.algaeScoredInNet + b.processedAlgaeScored)
                              .compareTo(a.algaeScoredInNet + a.processedAlgaeScored));
                          }).map((records) => records.first).toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComparisonPage(records: orderedRecords),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(Icons.compare_arrows),
                        label: Text('Compare Teams (${_selectedRecords.length})'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _records.isEmpty
                ? Center(child: Text('No scouting records available'))
                : ListView.builder(
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[_records.length - 1 - index];
                      final isSelected = _selectedRecords.contains(record);
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                        child: ListTile(
                          title: Text('Match ${record.matchNumber} - Team ${record.teamNumber}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${record.matchType} - ${record.timestamp}'),
                              Text('Alliance: ${record.isRedAlliance ? "Red" : "Blue"}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleRecordSelection(record),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  await DataManager.deleteRecord(_records.length - 1 - index);
                                  _loadRecords();
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            _showRecordDetails(record);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showComparisonDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Compare Records',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedRecords.clear();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var record in _selectedRecords)
                        Expanded(
                          child: Card(
                            margin: EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Match ${record.matchNumber}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 8),
                                  Text('Team ${record.teamNumber}'),
                                  Text(record.isRedAlliance ? 'Red Alliance' : 'Blue Alliance'),
                                  Divider(),
                                  SizedBox(height: 8),
                                  Text('Auto Mode:'),
                                  Text('  • Cage Type: ${record.cageType}'),
                                  Text('  • Coral Preloaded: ${record.coralPreloaded ? "Yes" : "No"}'),
                                  Text('  • Taxis: ${record.taxis ? "Yes" : "No"}'),
                                  Text('  • Algae Removed: ${record.algaeRemoved}'),
                                  Text('  • Coral Placed: ${record.coralPlaced}'),
                                  Text('  • Auto RP: ${record.rankingPoint ? "Yes" : "No"}'),
                                  Text('  • Can Pickup: ${record.canPickupAlgae ? "Yes" : "No"}'),
                                  SizedBox(height: 8),
                                  Text('Teleop:'),
                                  Text('  • Net Algae: ${record.algaeScoredInNet}'),
                                  Text('  • Coral RP: ${record.coralRankingPoint ? "Yes" : "No"}'),
                                  Text('  • Algae Processed: ${record.algaeProcessed}'),
                                  Text('  • Processed Scored: ${record.processedAlgaeScored}'),
                                  Text('  • Processor Cycles: ${record.processorCycles}'),
                                  Text('  • Co-Op Point: ${record.coOpPoint ? "Yes" : "No"}'),
                                  SizedBox(height: 8),
                                  Text('Endgame:'),
                                  Text('  • Returned: ${record.returnedToBarge ? "Yes" : "No"}'),
                                  Text('  • Cage Hang: ${record.cageHang}'),
                                  Text('  • Barge RP: ${record.bargeRankingPoint ? "Yes" : "No"}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordDetails(ScoutingRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Match ${record.matchNumber} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailSection('Match Information', [
                'Time: ${record.timestamp}',
                'Type: ${record.matchType}',
                'Team: ${record.teamNumber}',
                'Alliance: ${record.isRedAlliance ? "Red" : "Blue"}',
              ]),
              _buildDetailSection('Autonomous', [
                'Cage Type: ${record.cageType}',
                'Coral Preloaded: ${record.coralPreloaded ? "Yes" : "No"}',
                'Taxis: ${record.taxis ? "Yes" : "No"}',
                'Algae Removed: ${record.algaeRemoved}',
                'Coral Placed: ${record.coralPlaced}',
                'Ranking Point: ${record.rankingPoint ? "Yes" : "No"}',
                'Can Pickup: ${record.canPickupAlgae ? "Yes" : "No"}',
              ]),
              _buildDetailSection('Teleop', [
                'Algae Scored in Net: ${record.algaeScoredInNet}',
                'Coral Ranking Point: ${record.coralRankingPoint ? "Yes" : "No"}',
                'Algae Processed: ${record.algaeProcessed}',
                'Processed Algae Scored: ${record.processedAlgaeScored}',
                'Processor Cycles: ${record.processorCycles}',
                'Co-Op Point: ${record.coOpPoint ? "Yes" : "No"}',
              ]),
              _buildDetailSection('Endgame', [
                'Returned to Barge: ${record.returnedToBarge ? "Yes" : "No"}',
                'Cage Hang: ${record.cageHang}',
                'Barge Ranking Point: ${record.bargeRankingPoint ? "Yes" : "No"}',
              ]),
              _buildDetailSection('Other', [
                'Breakdown: ${record.breakdown ? "Yes" : "No"}',
                'Comments: ${record.comments}',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
              child: Text(detail),
            )),
        Divider(),
      ],
    );
  }
}
