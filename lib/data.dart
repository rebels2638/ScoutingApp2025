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
import 'theme/app_theme.dart';

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
    this.robotPath,
    this.telemetry,
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
      'teamNumber': teamNumber,
      'matchNumber': matchNumber,
      'timestamp': timestamp,
      'matchType': matchType,
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
    );
  }

  Map<String, dynamic> toCompressedJson() {
    final Map<String, dynamic> json = {
      't': teamNumber,
      'm': matchNumber,
      'ts': timestamp,
      'mt': matchType,
      'ra': isRedAlliance ? 1 : 0,
      'ct': cageType,
      'cp': coralPreloaded ? 1 : 0,
      'tx': taxis ? 1 : 0,
      'ar': algaeRemoved,
      'cpl': coralPlaced,
      'rp': rankingPoint ? 1 : 0,
      'cpc': canPickupCoral ? 1 : 0,
      'cpa': canPickupAlgae ? 1 : 0,
      'asn': algaeScoredInNet,
      'crp': coralRankingPoint ? 1 : 0,
      'ap': algaeProcessed,
      'pas': processedAlgaeScored,
      'pc': processorCycles,
      'cop': coOpPoint ? 1 : 0,
      'rtb': returnedToBarge ? 1 : 0,
      'ch': cageHang,
      'brp': bargeRankingPoint ? 1 : 0,
      'bd': breakdown ? 1 : 0,
      'cm': comments,
      'aan': autoAlgaeInNet,
      'aap': autoAlgaeInProcessor,
      'cpm': coralPickupMethod,
    };

    // Only include robot path if it exists
    if (robotPath != null) {
      // Convert drawing lines to compressed format
      json['rp'] = robotPath!.map((line) => {
        'p': (line['points'] as List).map((p) => {
          'x': ((p['x'] as num).toDouble() * 10).round() / 10,
          'y': ((p['y'] as num).toDouble() * 10).round() / 10,
        }).toList(),
        'c': line['color'],
        'w': ((line['strokeWidth'] as num).toDouble() * 10).round() / 10,
      }).toList();
    }

    return json;
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
    );
  }

  List<dynamic> toCsvRow() {
    String robotPathStr = '';
    if (robotPath != null) {
      try {
        // Escape any pipe characters in the JSON string
        robotPathStr = jsonEncode(robotPath).replaceAll('|', '\\|');
      } catch (e) {
        print('Error encoding robotPath: $e');
      }
    }

    return [
      timestamp,
      matchNumber,
      matchType,
      teamNumber,
      isRedAlliance ? 1 : 0,
      cageType,
      coralPreloaded ? 1 : 0,
      taxis ? 1 : 0,
      algaeRemoved,
      coralPlaced,
      rankingPoint ? 1 : 0,
      canPickupCoral ? 1 : 0,
      canPickupAlgae ? 1 : 0,
      algaeScoredInNet,
      coralRankingPoint ? 1 : 0,
      algaeProcessed,
      processedAlgaeScored,
      processorCycles,
      coOpPoint ? 1 : 0,
      returnedToBarge ? 1 : 0,
      cageHang,
      bargeRankingPoint ? 1 : 0,
      breakdown ? 1 : 0,
      comments.replaceAll('|', '\\|'), // Escape pipes in comments
      autoAlgaeInNet,
      autoAlgaeInProcessor,
      coralPickupMethod,
      robotPathStr,
    ];
  }

  static List<String> getCsvHeaders() {
    return [
      'timestamp',
      'matchNumber',
      'matchType', 
      'teamNumber',
      'isRedAlliance',
      'cageType',
      'coralPreloaded',
      'taxis',
      'algaeRemoved',
      'coralPlaced',
      'rankingPoint',
      'canPickupCoral',
      'canPickupAlgae',
      'algaeScoredInNet',
      'coralRankingPoint',
      'algaeProcessed',
      'processedAlgaeScored',
      'processorCycles',
      'coOpPoint',
      'returnedToBarge',
      'cageHang',
      'bargeRankingPoint',
      'breakdown',
      'comments',
      'autoAlgaeInNet',
      'autoAlgaeInProcessor',
      'coralPickupMethod',
      'robotPath',
    ];
  }

  factory ScoutingRecord.fromCsvRow(List<dynamic> row) {
    List<Map<String, dynamic>>? pathData;
    if (row[27].toString().isNotEmpty) {
      try {
        // Unescape pipe characters before parsing JSON
        String robotPathStr = row[27].toString().replaceAll('\\|', '|');
        final decoded = jsonDecode(robotPathStr);
        if (decoded is List) {
          pathData = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      } catch (e) {
        print('Error decoding robotPath: $e');
      }
    }

    return ScoutingRecord(
      timestamp: row[0].toString(),
      matchNumber: int.parse(row[1].toString()),
      matchType: row[2].toString(),
      teamNumber: int.parse(row[3].toString()),
      isRedAlliance: row[4].toString() == '1',
      cageType: row[5].toString(),
      coralPreloaded: row[6].toString() == '1',
      taxis: row[7].toString() == '1',
      algaeRemoved: int.parse(row[8].toString()),
      coralPlaced: row[9].toString(),
      rankingPoint: row[10].toString() == '1',
      canPickupCoral: row[11].toString() == '1',
      canPickupAlgae: row[12].toString() == '1',
      algaeScoredInNet: int.parse(row[13].toString()),
      coralRankingPoint: row[14].toString() == '1',
      algaeProcessed: int.parse(row[15].toString()),
      processedAlgaeScored: int.parse(row[16].toString()),
      processorCycles: int.parse(row[17].toString()),
      coOpPoint: row[18].toString() == '1',
      returnedToBarge: row[19].toString() == '1',
      cageHang: row[20].toString(),
      bargeRankingPoint: row[21].toString() == '1',
      breakdown: row[22].toString() == '1',
      comments: row[23].toString().replaceAll('\\|', '|'), // Unescape pipes in comments
      autoAlgaeInNet: int.parse(row[24].toString()),
      autoAlgaeInProcessor: int.parse(row[25].toString()),
      coralPickupMethod: row[26].toString(),
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
      
      // Convert records to CSV
      final csvData = [
        ScoutingRecord.getCsvHeaders(),
        ...records.map((r) => r.toCsvRow()),
      ];
      
      final csv = const ListToCsvConverter(fieldDelimiter: '|').convert(csvData);
      await prefs.setString(_storageKey, csv);
    } catch (e, stackTrace) {
      print('Error saving record: $e');
      print('Stack trace: $stackTrace');
      throw e;
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
      print('Stack trace: $stackTrace');
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

class DataPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Data'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: () => _showQRDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () => _showTeamAnalysis(context),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Export Data'),
                ),
                onTap: () => _exportData(context),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Import Data'),
                ),
                onTap: () => _importData(context),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.qr_code_scanner),
                  title: Text('Scan QR Code'),
                ),
                onTap: () => _scanQRCode(context),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Delete All', style: TextStyle(color: Colors.red)),
                ),
                onTap: () => _confirmDeleteAll(context),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<ScoutingRecord>>(
        future: DataManager.getRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_sim, size: 64, color: Colors.grey),
                  SizedBox(height: AppSpacing.md),
                  Text('No scouting data available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final record = snapshot.data![index];
                      return ScoutingRecordCard(
                        record: record,
                        onCompare: () => _showComparisonDialog(context, record),
                        onDelete: () => _confirmDelete(context, record),
                      );
                    },
                    childCount: snapshot.data!.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final records = await DataManager.getRecords();
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamAnalysisPage(allRecords: records),
            ),
          );
        },
        child: Icon(Icons.analytics),
        tooltip: 'Team Analysis',
      ),
    );
  }

  void _showQRDialog(BuildContext context) {
    // Implementation
  }

  void _showTeamAnalysis(BuildContext context) async {
    final records = await DataManager.getRecords();
    if (!context.mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamAnalysisPage(allRecords: records),
      ),
    );
  }

  void _showComparisonDialog(BuildContext context, ScoutingRecord record) {
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

  void _confirmDelete(BuildContext context, ScoutingRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Record'),
        content: Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DataManager.deleteRecord(0);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Records'),
        content: Text('Are you sure you want to delete all records? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await DataManager.deleteAllRecords();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('All records deleted')),
              );
            },
            child: Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    // Implementation
  }

  void _importData(BuildContext context) {
    // Implementation
  }

  void _scanQRCode(BuildContext context) {
    // Implementation
  }
}

class ScoutingRecordCard extends StatelessWidget {
  final ScoutingRecord record;
  final VoidCallback onCompare;
  final VoidCallback onDelete;

  const ScoutingRecordCard({
    required this.record,
    required this.onCompare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onCompare,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team ${record.teamNumber}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance,
                          ),
                        ),
                        Text(
                          '${record.matchType} Match ${record.matchNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricRow('Auto Algae', record.algaeRemoved.toString()),
                  _buildMetricRow('Teleop Algae', record.algaeScoredInNet.toString()),
                  _buildMetricRow('Processed', record.algaeProcessed.toString()),
                  if (record.comments.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        record.comments,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
