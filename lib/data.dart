import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'comparison.dart';
import 'team_analysis.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:csv/csv.dart';
import 'drawing_page.dart';
import 'qr_scanner_page.dart';

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
  
  final List<Map<String, dynamic>>? robotPath;
  
  String? telemetry;
  
  final String feederStation;
  
  // Add coral height fields
  final int coralOnReefHeight1;
  final int coralOnReefHeight2;
  final int coralOnReefHeight3;
  final int coralOnReefHeight4;
  
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
    required this.coralOnReefHeight1,
    required this.coralOnReefHeight2,
    required this.coralOnReefHeight3,
    required this.coralOnReefHeight4,
    this.robotPath,
    this.telemetry,
    required this.feederStation,
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

  Map<String, dynamic> toJson() {
    return {
      // Match info
      'matchNumber': matchNumber,
      'matchType': matchType,
      'timestamp': timestamp,
      'teamNumber': teamNumber,
      'isRedAlliance': isRedAlliance,
      
      // Auto
      'cageType': cageType,
      'coralPreloaded': coralPreloaded,
      'taxis': taxis,
      'algaeRemoved': algaeRemoved,
      'coralPlaced': coralPlaced,
      'rankingPoint': rankingPoint,
      'canPickupCoral': canPickupCoral,
      'canPickupAlgae': canPickupAlgae,
      'autoAlgaeInNet': autoAlgaeInNet,
      'autoAlgaeInProcessor': autoAlgaeInProcessor,
      'coralPickupMethod': coralPickupMethod,
      
      // Teleop
      'coralOnReefHeight1': coralOnReefHeight1,
      'coralOnReefHeight2': coralOnReefHeight2,
      'coralOnReefHeight3': coralOnReefHeight3,
      'coralOnReefHeight4': coralOnReefHeight4,
      'feederStation': feederStation,
      'algaeScoredInNet': algaeScoredInNet,
      'coralRankingPoint': coralRankingPoint,
      'algaeProcessed': algaeProcessed,
      'processedAlgaeScored': processedAlgaeScored,
      'processorCycles': processorCycles,
      'coOpPoint': coOpPoint,
      
      // Endgame
      'returnedToBarge': returnedToBarge,
      'cageHang': cageHang,
      'bargeRankingPoint': bargeRankingPoint,
      
      // Other
      'breakdown': breakdown,
      'comments': comments,
      'robotPath': robotPath,
      'telemetry': telemetry,
    };
  }

  factory ScoutingRecord.fromJson(Map<String, dynamic> json) {
    return ScoutingRecord(
      teamNumber: json['teamNumber'],
      matchNumber: json['matchNumber'],
      timestamp: json['timestamp'] ?? '',
      matchType: json['matchType'] ?? 'Unset',
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
      coralOnReefHeight1: json['coralOnReefHeight1'] ?? 0,
      coralOnReefHeight2: json['coralOnReefHeight2'] ?? 0,
      coralOnReefHeight3: json['coralOnReefHeight3'] ?? 0,
      coralOnReefHeight4: json['coralOnReefHeight4'] ?? 0,
      robotPath: json['robotPath'] != null
          ? (json['robotPath'] as List).map((line) {
              final Map<String, dynamic> lineMap = Map<String, dynamic>.from(line);
              return {
                'points': lineMap['points'],
                'color': lineMap['color'],
                'strokeWidth': lineMap['strokeWidth'],
              };
            }).toList()
          : null,
      telemetry: json['telemetry'] as String?,
      feederStation: json['feederStation'] ?? 'None',
    );
  }

  Map<String, dynamic> toCompressedJson() {
    return {
      // Match info
      'm': matchNumber,
      'mt': matchType,
      'ts': timestamp,
      't': teamNumber,
      'ra': isRedAlliance ? 1 : 0,
      
      // Auto
      'ct': cageType,
      'cp': coralPreloaded ? 1 : 0,
      'tx': taxis ? 1 : 0,
      'ar': algaeRemoved,
      'cpl': coralPlaced,
      'rp': rankingPoint ? 1 : 0,
      'cpc': canPickupCoral ? 1 : 0,
      'cpa': canPickupAlgae ? 1 : 0,
      'aan': autoAlgaeInNet,
      'aap': autoAlgaeInProcessor,
      'cpm': coralPickupMethod,
      
      // Teleop
      'ch1': coralOnReefHeight1,
      'ch2': coralOnReefHeight2,
      'ch3': coralOnReefHeight3,
      'ch4': coralOnReefHeight4,
      'fs': feederStation,
      'asn': algaeScoredInNet,
      'crp': coralRankingPoint ? 1 : 0,
      'ap': algaeProcessed,
      'pas': processedAlgaeScored,
      'pc': processorCycles,
      'cop': coOpPoint ? 1 : 0,
      
      // Endgame
      'rtb': returnedToBarge ? 1 : 0,
      'ch': cageHang,
      'brp': bargeRankingPoint ? 1 : 0,
      
      // Other
      'bd': breakdown ? 1 : 0,
      'cm': comments,
      'rp': robotPath,
      'tel': telemetry,
    };
  }

  static ScoutingRecord fromCompressedJson(Map<String, dynamic> json) {
    return ScoutingRecord(
      teamNumber: json['t'] as int,
      matchNumber: json['m'] as int,
      timestamp: json['ts'] as String,
      matchType: json['mt'] as String,
      isRedAlliance: json['ra'] == 1,
      cageType: json['ct'] as String,
      coralPreloaded: json['cp'] == 1,
      taxis: json['tx'] == 1,
      algaeRemoved: json['ar'] as int,
      coralPlaced: json['cpl'] as String,
      rankingPoint: json['rp'] == 1,
      canPickupCoral: json['cpc'] == 1,
      canPickupAlgae: json['cpa'] == 1,
      algaeScoredInNet: json['asn'] as int,
      coralRankingPoint: json['crp'] == 1,
      algaeProcessed: json['ap'] as int,
      processedAlgaeScored: json['pas'] as int,
      processorCycles: json['pc'] as int,
      coOpPoint: json['cop'] == 1,
      returnedToBarge: json['rtb'] == 1,
      cageHang: json['ch'] as String,
      bargeRankingPoint: json['brp'] == 1,
      breakdown: json['bd'] == 1,
      comments: json['cm'] as String,
      autoAlgaeInNet: json['aan'] as int,
      autoAlgaeInProcessor: json['aap'] as int,
      coralPickupMethod: json['cpm'] as String,
      coralOnReefHeight1: json['ch1'] as int,
      coralOnReefHeight2: json['ch2'] as int,
      coralOnReefHeight3: json['ch3'] as int,
      coralOnReefHeight4: json['ch4'] as int,
      robotPath: json['rp'] != null ? (json['rp'] as List).map((line) {
        return {
          'points': (line['p'] as List).map((p) => {
            'x': (p['x'] as num).toDouble(),
            'y': (p['y'] as num).toDouble(),
          }).toList(),
          'color': line['c'],
          'strokeWidth': line['w'],
        };
      }).toList() : null,
      feederStation: json['fs'] as String,
      telemetry: json['tel'] as String?,
    );
  }

  List<dynamic> toCsvRow() {
    String robotPathStr = '';
    if (robotPath != null) {
      try {
        robotPathStr = jsonEncode(robotPath).replaceAll('|', '\\|');
      } catch (e) {
        print('Error encoding robotPath: $e');
      }
    }

    return [
      // Match info
      matchNumber,
      matchType,
      timestamp,
      teamNumber,
      isRedAlliance ? 1 : 0,
      
      // Auto
      cageType,
      coralPreloaded ? 1 : 0,
      taxis ? 1 : 0,
      algaeRemoved,
      coralPlaced,
      rankingPoint ? 1 : 0,
      canPickupCoral ? 1 : 0,
      canPickupAlgae ? 1 : 0,
      autoAlgaeInNet,
      autoAlgaeInProcessor,
      coralPickupMethod,
      
      // Teleop
      coralOnReefHeight1,
      coralOnReefHeight2,
      coralOnReefHeight3,
      coralOnReefHeight4,
      feederStation,
      algaeScoredInNet,
      coralRankingPoint ? 1 : 0,
      algaeProcessed,
      processedAlgaeScored,
      processorCycles,
      coOpPoint ? 1 : 0,
      
      // Endgame
      returnedToBarge ? 1 : 0,
      cageHang,
      bargeRankingPoint ? 1 : 0,
      
      // Other
      breakdown ? 1 : 0,
      comments.replaceAll('|', '\\|'),
      robotPathStr,
    ];
  }

  static List<String> getCsvHeaders() {
    return [
      // Match info
      'matchNumber',
      'matchType',
      'timestamp',
      'teamNumber',
      'isRedAlliance',
      
      // Auto
      'cageType',
      'coralPreloaded',
      'taxis',
      'algaeRemoved',
      'coralPlaced',
      'rankingPoint',
      'canPickupCoral',
      'canPickupAlgae',
      'autoAlgaeInNet',
      'autoAlgaeInProcessor',
      'coralPickupMethod',
      
      // Teleop
      'coralOnReefHeight1',
      'coralOnReefHeight2',
      'coralOnReefHeight3',
      'coralOnReefHeight4',
      'feederStation',
      'algaeScoredInNet',
      'coralRankingPoint',
      'algaeProcessed',
      'processedAlgaeScored',
      'processorCycles',
      'coOpPoint',
      
      // Endgame
      'returnedToBarge',
      'cageHang',
      'bargeRankingPoint',
      
      // Other
      'breakdown',
      'comments',
      'robotPath',
    ];
  }

  factory ScoutingRecord.fromCsvRow(List<dynamic> row) {
    List<Map<String, dynamic>>? pathData;
    if (row[32].toString().isNotEmpty) {
      try {
        String robotPathStr = row[32].toString().replaceAll('\\|', '|');
        final decoded = jsonDecode(robotPathStr);
        if (decoded is List) {
          pathData = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      } catch (e) {
        print('Error decoding robotPath: $e');
      }
    }

    return ScoutingRecord(
      // Match info
      matchNumber: int.parse(row[0].toString()),
      matchType: row[1].toString(),
      timestamp: row[2].toString(),
      teamNumber: int.parse(row[3].toString()),
      isRedAlliance: row[4].toString() == '1',
      
      // Auto
      cageType: row[5].toString(),
      coralPreloaded: row[6].toString() == '1',
      taxis: row[7].toString() == '1',
      algaeRemoved: int.parse(row[8].toString()),
      coralPlaced: row[9].toString(),
      rankingPoint: row[10].toString() == '1',
      canPickupCoral: row[11].toString() == '1',
      canPickupAlgae: row[12].toString() == '1',
      autoAlgaeInNet: int.parse(row[13].toString()),
      autoAlgaeInProcessor: int.parse(row[14].toString()),
      coralPickupMethod: row[15].toString(),
      
      // Teleop
      coralOnReefHeight1: int.parse(row[16].toString()),
      coralOnReefHeight2: int.parse(row[17].toString()),
      coralOnReefHeight3: int.parse(row[18].toString()),
      coralOnReefHeight4: int.parse(row[19].toString()),
      feederStation: row[20].toString(),
      algaeScoredInNet: int.parse(row[21].toString()),
      coralRankingPoint: row[22].toString() == '1',
      algaeProcessed: int.parse(row[23].toString()),
      processedAlgaeScored: int.parse(row[24].toString()),
      processorCycles: int.parse(row[25].toString()),
      coOpPoint: row[26].toString() == '1',
      
      // Endgame
      returnedToBarge: row[27].toString() == '1',
      cageHang: row[28].toString(),
      bargeRankingPoint: row[29].toString() == '1',
      
      // Other
      breakdown: row[30].toString() == '1',
      comments: row[31].toString().replaceAll('\\|', '|'),
      robotPath: pathData,
    );
  }
}

class DataManager {
  static const String _storageKey = 'scouting_records';
  
  static Future<void> saveRecord(ScoutingRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await getRecords();
      records.add(record);
      
      final csvData = [
        ScoutingRecord.getCsvHeaders(),
        ...records.map((r) => r.toCsvRow()),
      ];
      
      final csv = const ListToCsvConverter(fieldDelimiter: '|').convert(csvData);
      await prefs.setString(_storageKey, csv);
      
      print('Record saved successfully. Total records: ${records.length}');
      print('CSV data: $csv');
    } catch (e, stackTrace) {
      print('Error saving record: $e');
      print(stackTrace);
      throw Exception('Failed to save record: $e');
    }
  }
  
  static Future<List<ScoutingRecord>> getRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? csvData = prefs.getString(_storageKey);
      if (csvData == null || csvData.isEmpty) return [];
      
      final List<List<dynamic>> rows = const CsvToListConverter(fieldDelimiter: '|').convert(csvData);
      if (rows.isEmpty || rows.length <= 1) return [];
      
      // Skip header row and convert remaining rows
      return rows.skip(1).map((row) {
        try {
          return ScoutingRecord.fromCsvRow(row);
        } catch (e) {
          print('Error parsing row: $e');
          print('Row data: $row');
          return null;
        }
      }).where((record) => record != null).cast<ScoutingRecord>().toList();
    } catch (e, stackTrace) {
      print('Error getting records: $e');
      print(stackTrace);
      return [];
    }
  }

  static Future<void> deleteRecord(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    records.removeAt(index);
    await prefs.setString(_storageKey, const ListToCsvConverter(fieldDelimiter: '|').convert([
      ScoutingRecord.getCsvHeaders(),
      ...records.map((r) => r.toCsvRow()),
    ]));
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
    await prefs.setString(_storageKey, const ListToCsvConverter(fieldDelimiter: '|').convert([
      ScoutingRecord.getCsvHeaders(),
      ...records.map((r) => r.toCsvRow()),
    ]));
  }

  static Future<void> exportToJson() async {
    try {
      final records = await getRecords();
      if (records.isEmpty) {
        throw Exception('No records to export');
      }

      final csvData = [
        ScoutingRecord.getCsvHeaders(),
        ...records.map((r) => r.toCsvRow()),
      ];
      
      final csv = const ListToCsvConverter(fieldDelimiter: '|').convert(csvData);
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Scouting Records',
        fileName: 'scouting_records.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      
      if (outputFile == null) {
        throw Exception('Export cancelled');
      }

      if (!outputFile.toLowerCase().endsWith('.csv')) {
        outputFile += '.csv';
      }

      await File(outputFile).writeAsString(csv, flush: true);
    } catch (e) {
      throw Exception('Failed to export: ${e.toString()}');
    }
  }

  static Future<void> importFromJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
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

      final csvStr = await file.readAsString();
      if (csvStr.isEmpty) {
        throw Exception('File is empty');
      }
      
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvStr);
      if (rows.length <= 1) {
        throw Exception('No records found in file');
      }

      // Skip header row and convert remaining rows to records
      final records = rows.skip(1).map((row) => ScoutingRecord.fromCsvRow(row)).toList();
      
      final prefs = await SharedPreferences.getInstance();
      final csvData = const ListToCsvConverter().convert([
        ScoutingRecord.getCsvHeaders(),
        ...records.map((r) => r.toCsvRow()),
      ]);
      await prefs.setString(_storageKey, csvData);
    } catch (e) {
      throw Exception('Failed to import: ${e.toString()}');
    }
  }

  static Future<void> deleteAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
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
                                      String matchNumber = fields[0].trim(); 
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QrScannerPage()),
                        );
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
                      label: Text('Scan QR Code'),
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
                      final record = _records[_records.length - 1 - index];
                      final isSelected = selectedRecords[_records.length - 1 - index];
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
                                    selectedRecords[_records.length - 1 - index] = value ?? false;
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
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Match ${record.matchNumber} Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Match Information', [
                        _buildDetailRow('Time', record.timestamp),
                        _buildDetailRow('Type', record.matchType),
                        _buildDetailRow('Team', record.teamNumber.toString()),
                        _buildDetailRow('Alliance', record.isRedAlliance ? "Red" : "Blue"),
                      ]),
                      _buildDetailSection('Autonomous', [
                        _buildDetailRow('Cage Type', record.cageType),
                        _buildDetailRow('Coral Preloaded', record.coralPreloaded ? "Yes" : "No"),
                        _buildDetailRow('Taxis', record.taxis ? "Yes" : "No"),
                        _buildDetailRow('Algae Removed', record.algaeRemoved.toString()),
                        _buildDetailRow('Coral Placed', record.coralPlaced),
                        _buildDetailRow('Ranking Point', record.rankingPoint ? "Yes" : "No"),
                        _buildDetailRow('Can Pickup Coral', record.canPickupCoral ? "Yes" : "No"),
                        _buildDetailRow('Can Pickup Algae', record.canPickupAlgae ? "Yes" : "No"),
                        _buildDetailRow('Auto Algae in Net', record.autoAlgaeInNet.toString()),
                        _buildDetailRow('Auto Algae in Processor', record.autoAlgaeInProcessor.toString()),
                        _buildDetailRow('Coral Pickup Method', record.coralPickupMethod),
                      ]),
                      _buildDetailSection('Teleop', [
                        _buildDetailRow('Coral on Reef (Height 1)', record.coralOnReefHeight1.toString()),
                        _buildDetailRow('Coral on Reef (Height 2)', record.coralOnReefHeight2.toString()),
                        _buildDetailRow('Coral on Reef (Height 3)', record.coralOnReefHeight3.toString()),
                        _buildDetailRow('Coral on Reef (Height 4)', record.coralOnReefHeight4.toString()),
                        _buildDetailRow('Feeder Station Used', record.feederStation),
                        _buildDetailRow('Algae Scored in Net', record.algaeScoredInNet.toString()),
                        _buildDetailRow('Coral Ranking Point', record.coralRankingPoint ? "Yes" : "No"),
                        _buildDetailRow('Algae Processed', record.algaeProcessed.toString()),
                        _buildDetailRow('Processed Algae Scored', record.processedAlgaeScored.toString()),
                        _buildDetailRow('Processor Cycles', record.processorCycles.toString()),
                        _buildDetailRow('Co-Op Point', record.coOpPoint ? "Yes" : "No"),
                      ]),
                      _buildDetailSection('Endgame', [
                        _buildDetailRow('Returned to Barge', record.returnedToBarge ? "Yes" : "No"),
                        _buildDetailRow('Cage Hang', record.cageHang),
                        _buildDetailRow('Barge Ranking Point', record.bargeRankingPoint ? "Yes" : "No"),
                      ]),
                      _buildDetailSection('Other', [
                        _buildDetailRow('Breakdown', record.breakdown ? "Yes" : "No"),
                        _buildDetailRow('Comments', record.comments),
                      ]),
                      if (record.robotPath != null)
                        _buildDetailSection('Robot Path', [
                          _buildDetailRow('Status', 'Drawing saved'),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DrawingPage(
                                      isRedAlliance: record.isRedAlliance,
                                      initialDrawing: record.robotPath,
                                      readOnly: true,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.visibility),
                              label: Text('View Drawing'),
                            ),
                          ),
                        ]),
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

  Widget _buildDetailSection(String title, List<dynamic> details) {
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
          child: detail is String ? Text(detail) : detail,
        )),
        Divider(),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
