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
import 'database_helper.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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
    'robotPath': robotPath,
    'telemetry': telemetry,
  };

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
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  List<ScoutingRecord> _records = [];
  
  // Add back the static methods that were removed
  static Future<void> saveRecord(ScoutingRecord record) async {
    try {
      final records = await DatabaseHelper.instance.getAllRecords();
      records.add(record);
      await DatabaseHelper.instance.saveRecords(records);
    } catch (e) {
      print('Error saving record: $e');
      throw e;
    }
  }

  static Future<List<ScoutingRecord>> getRecords() async {
    try {
      return await DatabaseHelper.instance.getAllRecords();
    } catch (e) {
      print('Error getting records: $e');
      return [];
    }
  }

  static Future<void> deleteRecord(int index) async {
    try {
      final records = await DatabaseHelper.instance.getAllRecords();
      records.removeAt(index);
      await DatabaseHelper.instance.saveRecords(records);
    } catch (e) {
      print('Error deleting record: $e');
      throw e;
    }
  }

  static Future<void> deleteAllRecords() async {
    try {
      await DatabaseHelper.instance.deleteAllRecords();
    } catch (e) {
      print('Error deleting all records: $e');
      throw e;
    }
  }

  // Instance methods
  Future<void> loadRecords() async {
    _records = await DatabaseHelper.instance.getAllRecords();
  }

  List<ScoutingRecord> getRecordsForTeams(Set<int> teamNumbers) {
    if (teamNumbers.isEmpty) return _records;
    return _records.where((r) => teamNumbers.contains(r.teamNumber)).toList();
  }

  List<int> getAllTeamNumbers() {
    return _records.map((r) => r.teamNumber).toSet().toList()..sort();
  }

  // Keep existing statistics and history methods
  Map<String, dynamic> getTeamStats(int teamNumber) {
    final teamRecords = _records.where((r) => r.teamNumber == teamNumber).toList();
    if (teamRecords.isEmpty) return {};

    return {
      'matches': teamRecords.length,
      'avgAutoAlgae': _average(teamRecords.map((r) => r.algaeRemoved)),
      'avgTeleopAlgae': _average(teamRecords.map((r) => r.algaeScoredInNet)),
      'avgProcessed': _average(teamRecords.map((r) => r.algaeProcessed)),
      'avgCycles': _average(teamRecords.map((r) => r.processorCycles)),
      'taxisSuccess': _percentSuccess(teamRecords.map((r) => r.taxis)),
      'hangSuccess': _percentSuccess(teamRecords.map((r) => r.cageHang != 'None')),
      'breakdowns': teamRecords.where((r) => r.breakdown).length,
    };
  }

  double _average(Iterable<num> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _percentSuccess(Iterable<bool> values) {
    if (values.isEmpty) return 0;
    return values.where((v) => v).length / values.length * 100;
  }

  List<Map<String, dynamic>> getTeamMatchHistory(int teamNumber) {
    return _records
        .where((r) => r.teamNumber == teamNumber)
        .map((r) => {
              'matchNumber': r.matchNumber,
              'matchType': r.matchType,
              'autoAlgae': r.algaeRemoved,
              'teleopAlgae': r.algaeScoredInNet,
              'processed': r.algaeProcessed,
              'hang': r.cageHang,
              'breakdown': r.breakdown,
            })
        .toList();
  }
}

class DataPage extends StatefulWidget {
  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List<ScoutingRecord> records = [];
  Set<int> selectedRecordIndices = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedRecords = await DataManager.getRecords();
    setState(() {
      records = loadedRecords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Data'),
        actions: [
          if (selectedRecordIndices.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: FilledButton.icon(
                icon: Icon(Icons.compare_arrows),
                label: Text('Compare (${selectedRecordIndices.length})'),
                onPressed: () {
                  final selectedRecords = selectedRecordIndices
                      .map((i) => records[i])
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComparisonPage(records: selectedRecords),
                    ),
                  );
                },
              ),
            ),
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: () => _showQRCodeDialog(context),
            tooltip: 'Generate QR Code',
          ),
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () => _showTeamAnalysis(context),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Clear Selection'),
                enabled: selectedRecordIndices.isNotEmpty,
                onTap: () {
                  setState(() => selectedRecordIndices.clear());
                },
              ),
              PopupMenuItem(
                child: Text('Import Data'),
                onTap: () {
                  Future.delayed(Duration.zero, () => _importData());
                },
              ),
              PopupMenuItem(
                child: Text('Export Data'),
                onTap: () {
                  Future.delayed(Duration.zero, () => _exportData());
                },
              ),
              PopupMenuItem(
                child: Text('Delete All Data'),
                onTap: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: records.length,
        padding: EdgeInsets.all(AppSpacing.md),
        itemBuilder: (context, index) {
          final record = records[index];
          return ScoutingRecordCard(
            record: record,
            isSelected: selectedRecordIndices.contains(index),
            onSelected: (selected) {
              setState(() {
                if (selected ?? false) {
                  selectedRecordIndices.add(index);
                } else {
                  selectedRecordIndices.remove(index);
                }
              });
            },
            onDelete: () => _showDeleteConfirmation(context, index),
          );
        },
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('What data would you like to include?'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _generateQRCode(selectedRecordsOnly: true);
                  },
                  child: Text('Selected Only'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _generateQRCode(selectedRecordsOnly: false);
                  },
                  child: Text('All Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generateQRCode({required bool selectedRecordsOnly}) {
    final dataToEncode = selectedRecordsOnly
        ? selectedRecordIndices.map((i) => records[i]).toList()
        : records;
        
    final jsonData = jsonEncode(dataToEncode.map((r) => {
      'teamNumber': r.teamNumber,
      'matchNumber': r.matchNumber,
      'matchType': r.matchType,
      // ... add other fields you want to include
    }).toList());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(selectedRecordsOnly ? 'Selected Records QR' : 'All Records QR'),
        content: Container(
          width: 300,
          height: 300,
          child: QrImageView(
            data: jsonData,
            version: QrVersions.auto,
            size: 300.0,
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

  void _showDeleteConfirmation(BuildContext context, [int? index]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index != null ? 'Delete Record' : 'Delete All Data'),
        content: Text(
          index != null 
              ? 'Are you sure you want to delete this record? This cannot be undone.'
              : 'Are you sure you want to delete all data? This cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              if (index != null) {
                await DataManager.deleteRecord(index);
                await _loadData(); // Reload the data
              } else {
                await DataManager.deleteAllRecords();
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                  index != null ? 'Record deleted' : 'All data deleted'
                )),
              );
            },
            child: Text(index != null ? 'Delete' : 'Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    // Use file_picker to let the user choose a file and load CSV data.
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final csvData = await file.readAsString();
        // Parse CSV data (assuming same format as exported)
        final List<List<dynamic>> rows = const CsvToListConverter(fieldDelimiter: '|').convert(csvData);
        // Skip header and create ScoutingRecords.
        final newRecords = rows.skip(1).map((row) => ScoutingRecord.fromCsvRow(row)).toList();
        // Save the new records (this example replaces existing data).
        await DatabaseHelper.instance.saveRecords(newRecords);
        setState(() {
          records = newRecords;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data imported successfully')));
      }
    } catch (e) {
      print('Error importing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing data')));
    }
  }
  
  Future<void> _exportData() async {
    try {
      // Convert current records to CSV.
      final csvData = [
        ScoutingRecord.getCsvHeaders(),
        ...records.map((r) => r.toCsvRow()),
      ];
      final csv = const ListToCsvConverter(fieldDelimiter: '|').convert(csvData);
      // (Here, you can write the CSV data to a file or share it.)
      // For demonstration, we copy it to the clipboard.
      await Clipboard.setData(ClipboardData(text: csv));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV data copied to clipboard')));
    } catch (e) {
      print('Error exporting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting data')));
    }
  }
}

class ScoutingRecordCard extends StatelessWidget {
  final ScoutingRecord record;
  final VoidCallback onDelete;
  final bool isSelected;
  final Function(bool?) onSelected;

  const ScoutingRecordCard({
    required this.record,
    required this.onDelete,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: (record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance)
                  .withOpacity(isSelected ? 0.3 : 0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: onSelected,
                  activeColor: record.isRedAlliance ? 
                    AppColors.redAlliance : 
                    AppColors.blueAlliance,
                ),
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
                  icon: Icon(Icons.qr_code),
                  onPressed: () => _showSingleRecordQR(context, record),
                  tooltip: 'Generate QR for this record',
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
    );
  }

  void _showSingleRecordQR(BuildContext context, ScoutingRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record QR Code'),
        content: Container(
          width: 300,
          height: 300,
          child: QrImageView(
            data: jsonEncode(record.toJson()),
            version: QrVersions.auto,
            size: 300.0,
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

// Add this extension for median calculation
extension ListNumberExtension on List<num> {
  double median() {
    if (isEmpty) return 0;
    final sorted = List<num>.from(this)..sort();
    final middle = length ~/ 2;
    if (length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    }
    return sorted[middle].toDouble();
  }
}
