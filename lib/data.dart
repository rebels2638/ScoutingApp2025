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
import 'record_detail.dart';

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
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  List<ScoutingRecord> _records = [];
  
  // Add back the static methods that were removed
  static Future<void> saveRecord(ScoutingRecord record) async {
    try {
      final records = await DatabaseHelper.instance.getAllRecords();
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
      return await DatabaseHelper.instance.getAllRecords();
    } catch (e) {
      print('Error getting records: $e');
      print('Stack trace: $stackTrace');
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
  const DataPage({Key? key}) : super(key: key);

  @override
  DataPageState createState() => DataPageState();
}

class DataPageState extends State<DataPage> with WidgetsBindingObserver {
  List<ScoutingRecord> _records = [];
  Set<int> selectedRecords = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadRecords();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadRecords();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadRecords();
  }

  Future<void> loadRecords() async {
    List<ScoutingRecord> recs = await DatabaseHelper.instance.getAllRecords();
    if (mounted) {
      setState(() {
        _records = recs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Data'),
        actions: [
          if (selectedRecords.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: FilledButton.icon(
                icon: Icon(Icons.compare_arrows),
                label: Text('Compare (${selectedRecords.length})'),
                onPressed: () {
                  final selectedList = _records
                      .asMap()
                      .entries
                      .where((e) => selectedRecords.contains(e.key))
                      .map((e) => e.value)
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComparisonPage(records: selectedList),
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
                enabled: selectedRecords.isNotEmpty,
                onTap: () {
                  setState(() => selectedRecords.clear());
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
        itemCount: _records.length,
        padding: EdgeInsets.all(AppSpacing.md),
        itemBuilder: (context, index) {
          final record = _records[index];
          return ScoutingRecordCard(
            record: record,
            isSelected: selectedRecords.contains(index),
            onSelected: (selected) {
              setState(() {
                if (selected ?? false) {
                  selectedRecords.add(index);
                } else {
                  selectedRecords.remove(index);
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
    // TODO: Implement QR Code dialog
  }

  void _showTeamAnalysis(BuildContext context) {
    // TODO: Implement Team Analysis view
  }

  void _importData() {
    // TODO: Implement data import logic
  }

  void _exportData() {
    // TODO: Implement data export logic
  }

  void _showDeleteConfirmation(BuildContext context, [int? index]) {
    // TODO: Implement delete confirmation dialog
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
    );
  }

  Widget ScoutingRecordCard({
    required ScoutingRecord record,
    required bool isSelected,
    required ValueChanged<bool?> onSelected,
    required VoidCallback onDelete,
  }) {
    return Card(
      child: ListTile(
        title: Text('Match ${record.matchNumber} - Team ${record.teamNumber}'),
        subtitle: Text(record.matchType),
        selected: isSelected,
        onTap: () => onSelected(!isSelected),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: onDelete,
        ),
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
