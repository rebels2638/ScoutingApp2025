import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'comparison.dart';
import 'team_analysis.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:csv/csv.dart';

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
  final String coralPickupMethod;
  
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

  final int autoAlgaeInNet;
  final int autoAlgaeInProcessor;
  
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
    required this.autoAlgaeInNet,
    required this.autoAlgaeInProcessor,
    required this.coralPickupMethod,
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
    'autoAlgaeInNet': autoAlgaeInNet,
    'autoAlgaeInProcessor': autoAlgaeInProcessor,
    'coralPickupMethod': coralPickupMethod,
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
    autoAlgaeInNet: json['autoAlgaeInNet'] ?? 0,
    autoAlgaeInProcessor: json['autoAlgaeInProcessor'] ?? 0,
    coralPickupMethod: json['coralPickupMethod'] ?? 'None',
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

  static Future<void> deleteAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode([]));
  }

  static Future<void> deleteMultipleRecords(List<int> indices) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    indices.sort((a, b) => b.compareTo(a)); // sort descending order
    for (int index in indices) {
      if (index >= 0 && index < records.length) {
        records.removeAt(index);
      }
    }
    await prefs.setString(_storageKey, jsonEncode(records.map((r) => r.toJson()).toList()));
  }
}

class DataPage extends StatefulWidget {
  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List<ScoutingRecord> _records = [];
  List<bool> selectedRecords = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await DataManager.getRecords();
    if (mounted) {
      setState(() {
        _records = records;
        selectedRecords = List.generate(records.length, (index) => false);
      });
    }
  }

  void _toggleRecordSelection(int index) {
    if (index >= 0 && index < selectedRecords.length) {
      setState(() {
        selectedRecords[index] = !selectedRecords[index];
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Data'),
          content: Text('Are you sure?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
              ),
              onPressed: () async {
                // Show second confirmation for delete all
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Warning'),
                        ],
                      ),
                      content: Text('Are you sure you want to delete ALL data?'),
                      actions: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.black,
                          ),
                          onPressed: () async {
                            await DataManager.deleteAllRecords();
                            Navigator.pop(context);
                            _loadRecords();
                          },
                          child: Text('Yes'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('No'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Delete ALL data'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
              ),
              onPressed: () async {
                List<int> toDelete = [];
                for (int i = selectedRecords.length - 1; i >= 0; i--) {
                  if (selectedRecords[i]) {
                    toDelete.add(i);
                  }
                }
                await DataManager.deleteMultipleRecords(toDelete);
                Navigator.pop(context);
                _loadRecords();
              },
              child: Text('Delete selected data'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
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
                      label: Text('Export'),
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
                      label: Text('Import'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showDeleteConfirmation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? null 
                            : Colors.grey.shade200,
                        foregroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? null 
                            : Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? null 
                            : Colors.black
                      ),
                      label: Text('Delete'),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final records = await DataManager.getRecords();
                          if (records.isEmpty) {
                            throw Exception('No records to export');
                          }
                          List<ScoutingRecord> selected = [];
                          for (int i = 0; i < records.length; i++) {
                            if (selectedRecords[i]) {
                              selected.add(records[i]);
                            }
                          }

                          if (selected.isEmpty) {
                            throw Exception('No records selected');
                          }

                          List<List<dynamic>> csvData = [];
                          selected.forEach((record) {
                            csvData.add(record.toJson().values.toList());
                          });
                          String csv = const ListToCsvConverter().convert(csvData);
                          List<String> recordsCsv = csv.split('\n');

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Match QR Codes'),
                                content: Container(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    itemCount: recordsCsv.length,
                                    itemBuilder: (context, index) {
                                      List<String> fields = recordsCsv[index].split(',');
                                      String matchNumber = fields[1].trim(); 
                                      return Column(
                                        children: [
                                          Container(
                                            width: 200,
                                            height: 200,
                                            child: QrImageView(
                                              data: recordsCsv[index],
                                              version: QrVersions.auto,
                                              foregroundColor: Theme.of(context).brightness == Brightness.dark 
                                                  ? Colors.white 
                                                  : Colors.black,
                                              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                                  ? Colors.black 
                                                  : Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text('Match #$matchNumber'),
                                          Divider(),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Close'),
                                  ),
                                ],
                              );
                            },
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
                      icon: Icon(Icons.qr_code, color: Theme.of(context).brightness == Brightness.dark 
                          ? null 
                          : Colors.black),
                      label: Text('Show QR Code'),
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
                      icon: Icon(Icons.barcode_reader, color: Theme.of(context).brightness == Brightness.dark 
                          ? null 
                          : Colors.black),
                      label: Text('Scan Qr Code'),
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
                    if (selectedRecords.any((e) => e))
                      ElevatedButton.icon(
                        onPressed: () {
                          Map<int, List<ScoutingRecord>> teamRecords = {};
                          for (int i = 0; i < _records.length; i++) {
                            if (selectedRecords[i]) {
                              teamRecords.putIfAbsent(_records[i].teamNumber, () => []).add(_records[i]);
                            }
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
                        label: Text('Compare Teams (${selectedRecords.where((e) => e).length})'),
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
                      final record = _records[index];
                      final isSelected = selectedRecords[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                        child: Column(
                          children: [
                            ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    selectedRecords[index] = value ?? false;
                                  });
                                },
                              ),
                              title: Text('Match ${record.matchNumber} - Team ${record.teamNumber}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${record.matchType} - ${record.timestamp}'),
                                  Text('Alliance: ${record.isRedAlliance ? "Red" : "Blue"}'),
                                ],
                              ),
                              onTap: () {
                                _showRecordDetails(record);
                              },
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
      child: Text(
                                      'Transfer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showQrCodeForRecord(record);
                                    },
                                    icon: Icon(Icons.qr_code, size: 18),
                                    label: Text('Show QR Code'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

void _showQrCodeForRecord(ScoutingRecord record) {
  final csvData = [
    record.toJson().values.toList(),
  ];
  final csvStr = const ListToCsvConverter().convert(csvData);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Match ${record.matchNumber} - Team ${record.teamNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: csvStr,
                  version: QrVersions.auto,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.black 
                      : Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text('Scan to transfer data'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      );
    },
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
                        selectedRecords = List.generate(_records.length, (index) => false);
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
                      for (int i = 0; i < _records.length; i++)
                        if (selectedRecords[i])
                          Expanded(
                            child: Card(
                              margin: EdgeInsets.all(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Match ${_records[i].matchNumber}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    SizedBox(height: 8),
                                    Text('Team ${_records[i].teamNumber}'),
                                    Text(_records[i].isRedAlliance ? 'Red Alliance' : 'Blue Alliance'),
                                    Divider(),
                                    SizedBox(height: 8),
                                    Text('Auto Mode:'),
                                    Text('  • Cage Type: ${_records[i].cageType}'),
                                    Text('  • Coral Preloaded: ${_records[i].coralPreloaded ? "Yes" : "No"}'),
                                    Text('  • Taxis: ${_records[i].taxis ? "Yes" : "No"}'),
                                    Text('  • Algae Removed: ${_records[i].algaeRemoved}'),
                                    Text('  • Coral Placed: ${_records[i].coralPlaced}'),
                                    Text('  • Auto RP: ${_records[i].rankingPoint ? "Yes" : "No"}'),
                                    Text('  • Can Pickup: ${_records[i].canPickupAlgae ? "Yes" : "No"}'),
                                    SizedBox(height: 8),
                                    Text('Teleop:'),
                                    Text('  • Net Algae: ${_records[i].algaeScoredInNet}'),
                                    Text('  • Coral RP: ${_records[i].coralRankingPoint ? "Yes" : "No"}'),
                                    Text('  • Algae Processed: ${_records[i].algaeProcessed}'),
                                    Text('  • Processed Scored: ${_records[i].processedAlgaeScored}'),
                                    Text('  • Processor Cycles: ${_records[i].processorCycles}'),
                                    Text('  • Co-Op Point: ${_records[i].coOpPoint ? "Yes" : "No"}'),
                                    SizedBox(height: 8),
                                    Text('Endgame:'),
                                    Text('  • Returned: ${_records[i].returnedToBarge ? "Yes" : "No"}'),
                                    Text('  • Cage Hang: ${_records[i].cageHang}'),
                                    Text('  • Barge RP: ${_records[i].bargeRankingPoint ? "Yes" : "No"}'),
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
                'Auto Algae in Net: ${record.autoAlgaeInNet}',
                'Auto Algae in Processor: ${record.autoAlgaeInProcessor}',
                'Coral Pickup Method: ${record.coralPickupMethod}',
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
