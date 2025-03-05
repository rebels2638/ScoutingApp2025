import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import 'comparison.dart';
import 'team_analysis.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:csv/csv.dart';
import 'drawing_page.dart' as drawing;
import 'theme/app_theme.dart';
import 'database_helper.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'record_detail.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'qr_scanner_page.dart';
import 'services/ble_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auto_path_photo_page.dart';
import 'visualization_page.dart';
import 'qr_code_dialog.dart';

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
                'imagePath': lineMap['imagePath'],
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
          'imagePath': line['i'],
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
  const DataPage({Key? key}) : super(key: key);

  @override
  DataPageState createState() => DataPageState();
}

class DataPageState extends State<DataPage> {
  List<ScoutingRecord> _records = [];
  Set<int> selectedRecords = {};
  String _searchQuery = '';
  bool _isSelectionMode = false;
  bool _isLoading = false;
  bool _isScoutingLeader = false;

  @override
  void initState() {
    super.initState();
    loadRecords();
    _loadScoutingLeaderStatus();
  }

  Future<void> loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await DatabaseHelper.instance.getAllRecords();
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading records: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadScoutingLeaderStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isScoutingLeader = prefs.getBool('scouting_leader_enabled') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          _buildActionBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty 
                ? _buildEmptyState()
                : _buildRecordsList(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSearchAndFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.all(8),
      color: isDark 
          ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search by team number...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            filled: true,
            fillColor: isDark
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface,
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    if (!_isSelectionMode && selectedRecords.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Text(
            '${selectedRecords.length} selected',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (selectedRecords.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare),
              tooltip: 'Compare selected',
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
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete selected',
            onPressed: () => _showDeleteConfirmation(context),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Clear selection',
            onPressed: () {
              setState(() {
                selectedRecords.clear();
                _isSelectionMode = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    final filteredRecords = _records.where((record) {
      if (_searchQuery.isEmpty) return true;
      // Only filter by team number
      return record.teamNumber.toString().contains(_searchQuery);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredRecords.length,
      itemBuilder: (context, index) {
        final record = filteredRecords[index];
        return _buildRecordCard(record, index);
      },
    );
  }

  Widget _buildRecordCard(ScoutingRecord record, int index) {
    final isSelected = selectedRecords.contains(index);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected 
          ? (isDark 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.primaryContainer)
          : isDark 
              ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
              : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? (isDark
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.5))
              : isDark
                  ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                  : Colors.transparent,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                selectedRecords.remove(index);
                if (selectedRecords.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                selectedRecords.add(index);
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordDetailPage(record: record),
              ),
            );
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            if (isSelected) {
              selectedRecords.remove(index);
            } else {
              selectedRecords.add(index);
            }
          });
        },
        leading: _isSelectionMode 
            ? Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDark
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.2))
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? (isDark
                            ? Theme.of(context).colorScheme.primary
                            : Colors.blue)
                        : Colors.grey.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected 
                      ? (isDark
                          ? Theme.of(context).colorScheme.primary
                          : Colors.blue)
                      : Colors.grey.withOpacity(0.7),
                ),
              )
            : null,
        title: Row(
          children: [
            Text(
              'Team ${record.teamNumber}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected && isDark
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: record.isRedAlliance 
                    ? AppColors.redAlliance.withOpacity(isDark ? 0.3 : 0.1)
                    : AppColors.blueAlliance.withOpacity(isDark ? 0.3 : 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                record.isRedAlliance ? 'Red' : 'Blue',
                style: TextStyle(
                  color: record.isRedAlliance 
                      ? AppColors.redAlliance
                      : AppColors.blueAlliance,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${record.timestamp} Match ${record.matchNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            if (record.comments.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                record.comments,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showRecordOptions(context, record, index),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No scouting records yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start scouting matches to see them here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner),
          label: 'Scan QR Code',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QrScannerPage()),
            );
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.file_upload),
          label: 'Import Data',
          onTap: _importData,
        ),
        SpeedDialChild(
          child: const Icon(Icons.file_download),
          label: 'Export Data',
          onTap: _exportData,
        ),
        SpeedDialChild(
          child: const Icon(Icons.analytics),
          label: 'Team Analysis',
          onTap: () => _showTeamAnalysis(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.bar_chart),
          label: 'Visualizations',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisualizationPage(records: _records),
            ),
          ),
        ),
        SpeedDialChild(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          child: const Icon(Icons.delete_forever),
          label: 'Delete All Data',
          onTap: () => _showDeleteAllConfirmation(context),
        ),
      ],
    );
  }

  void _showRecordOptions(BuildContext context, ScoutingRecord record, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecordDetailPage(record: record),
                  ),
                );
              },
            ),
            if (record.robotPath != null)
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('View Auto Path'),
                onTap: () {
                  Navigator.pop(context);
                  // Find the first path with an image
                  final imagePath = record.robotPath?.firstWhere(
                    (path) => path['imagePath'] != null && File(path['imagePath'] as String).existsSync(),
                    orElse: () => {'imagePath': null},
                  )['imagePath'] as String?;
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => drawing.DrawingPage(
                        isRedAlliance: record.isRedAlliance,
                        initialDrawing: record.robotPath,
                        readOnly: true,
                        imagePath: imagePath,
                      ),
                    ),
                  );
                },
              ),
            if (_isScoutingLeader && (record.robotPath == null || record.robotPath!.isEmpty))
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Auto Path Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AutoPathPhotoPage(
                        isRedAlliance: record.isRedAlliance,
                      ),
                    ),
                  );
                  
                  if (result != null && mounted) {
                    // Get existing path data if any
                    List<Map<String, dynamic>> updatedPath = [];
                    if (record.robotPath != null) {
                      updatedPath.addAll(record.robotPath!);
                    }
                    // Add new path data
                    updatedPath.addAll(result as List<Map<String, dynamic>>);
                    
                    // Create updated record with new path
                    final updatedRecord = ScoutingRecord(
                      timestamp: record.timestamp,
                      matchNumber: record.matchNumber,
                      matchType: record.matchType,
                      teamNumber: record.teamNumber,
                      isRedAlliance: record.isRedAlliance,
                      cageType: record.cageType,
                      coralPreloaded: record.coralPreloaded,
                      taxis: record.taxis,
                      algaeRemoved: record.algaeRemoved,
                      coralPlaced: record.coralPlaced,
                      rankingPoint: record.rankingPoint,
                      canPickupCoral: record.canPickupCoral,
                      canPickupAlgae: record.canPickupAlgae,
                      algaeScoredInNet: record.algaeScoredInNet,
                      coralRankingPoint: record.coralRankingPoint,
                      algaeProcessed: record.algaeProcessed,
                      processedAlgaeScored: record.processedAlgaeScored,
                      processorCycles: record.processorCycles,
                      coOpPoint: record.coOpPoint,
                      returnedToBarge: record.returnedToBarge,
                      cageHang: record.cageHang,
                      bargeRankingPoint: record.bargeRankingPoint,
                      breakdown: record.breakdown,
                      comments: record.comments,
                      autoAlgaeInNet: record.autoAlgaeInNet,
                      autoAlgaeInProcessor: record.autoAlgaeInProcessor,
                      coralPickupMethod: record.coralPickupMethod,
                      coralOnReefHeight1: record.coralOnReefHeight1,
                      coralOnReefHeight2: record.coralOnReefHeight2,
                      coralOnReefHeight3: record.coralOnReefHeight3,
                      coralOnReefHeight4: record.coralOnReefHeight4,
                      feederStation: record.feederStation,
                      robotPath: updatedPath,
                      telemetry: record.telemetry,
                    );

                    // Update the record in the database
                    final records = await DatabaseHelper.instance.getAllRecords();
                    records[index] = updatedRecord;
                    await DatabaseHelper.instance.saveRecords(records);
                    
                    // Refresh the UI
                    setState(() {
                      _records = records;
                    });

                    // Show success message if the context is still valid
                    if (mounted && context.mounted) {
                      // Use a post-frame callback to ensure we're in a safe state
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Auto path photo saved successfully'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      });
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Generate QR Code'),
              onTap: () {
                Navigator.pop(context);
                _showQRCodeDialog(context, record);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, ScoutingRecord record) {
    showDialog(
      context: context,
      builder: (context) => QRCodeDialog(record: record),
    );
  }

  void _showTeamAnalysis(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamAnalysisPage(records: _records),
      ),
    );
  }

  void _importData() async {
    try {
      final XTypeGroup csvTypeGroup = XTypeGroup(
        label: 'CSV',
        extensions: ['csv'],
        // Add UTIs for iOS
        uniformTypeIdentifiers: ['public.comma-separated-values-text'],
      );
      
      final XFile? file = await openFile(
        acceptedTypeGroups: [csvTypeGroup],
      );

      if (file != null) {
        final contents = await file.readAsString();
        
        final List<List<dynamic>> rows = const CsvToListConverter(fieldDelimiter: '|').convert(contents);
        if (rows.length <= 1) throw Exception('No data found in file');
        
        // Get existing records
        final existingRecords = await DatabaseHelper.instance.getAllRecords();
        
        // Convert new records from CSV
        final newRecords = rows.skip(1).map((row) => ScoutingRecord.fromCsvRow(row)).toList();
        
        // Combine existing and new records
        final allRecords = [...existingRecords, ...newRecords];
        
        // Save combined records
        await DatabaseHelper.instance.saveRecords(allRecords);
        
        setState(() {
          loadRecords();
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${newRecords.length} records'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing data: $e')),
      );
    }
  }

  void _exportData() async {
    try {
      if (Platform.isAndroid) {
        // Request storage permissions based on Android version
        if (await Permission.manageExternalStorage.isDenied) {
          final status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission is required to export data. Please grant permission in Settings.'),
                  duration: Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Settings',
                    onPressed: openAppSettings,
                  ),
                ),
              );
              return;
            }
          }
        }
      }

      final csvData = [
        ScoutingRecord.getCsvHeaders(),
        ..._records.map((r) => r.toCsvRow()),
      ];
      
      final csv = const ListToCsvConverter(fieldDelimiter: '|').convert(csvData);
      final String dirPath = await _getExportDirectory();
      
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      
      final file = File('$dirPath/scouting_data_$timestamp.csv');
      await file.writeAsString(csv);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Platform.isAndroid 
            ? 'Data exported to Documents → 2638 Scout → Exports'
            : 'Data exported to Files App → 2638 Scout → Exports'
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              Share.shareFiles(
                [file.path],
                text: 'Scouting Data Export',
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }

  Future<String> _getExportDirectory() async {
    if (Platform.isIOS) {
      // On iOS, create a directory in the Documents folder that will be visible in Files app
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${appDocDir.path}/2638 Scout/Exports';
      
      // Create the directory if it doesn't exist
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dirPath;
    } else if (Platform.isAndroid) {
      Directory? directory;
      
      try {
        // Use Documents directory with a clear path structure
        if (await Permission.manageExternalStorage.isGranted) {
          directory = Directory('/storage/emulated/0/Documents/2638 Scout/Exports');
        } else {
          // Fallback to app-specific directory
          final appDir = await getExternalStorageDirectory();
          if (appDir == null) {
            throw Exception('Could not access external storage');
          }
          directory = Directory('${appDir.path}/2638 Scout/Exports');
        }
        
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory.path;
      } catch (e) {
        // Fallback to app's private directory if all else fails
        final appDir = await getApplicationDocumentsDirectory();
        directory = Directory('${appDir.path}/2638 Scout/Exports');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory.path;
      }
    } else {
      // Fallback for other platforms
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      return '${appDocDir.path}/2638 Scout/Exports';
    }
  }

  Future<List<FileSystemEntity>> listExports() async {
    final String dirPath = await _getExportDirectory();
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return [];
    }
    return dir.listSync().where((e) => e.path.endsWith('.csv')).toList();
  }

  void _showDeleteConfirmation(BuildContext context, [int? index]) {
    final bool isMultipleDelete = selectedRecords.isNotEmpty;
    final int deleteCount = isMultipleDelete ? selectedRecords.length : 1;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMultipleDelete 
          ? 'Delete $deleteCount Records?' 
          : 'Delete Record?'
        ),
        content: Text(isMultipleDelete
          ? 'Are you sure you want to delete $deleteCount selected records? This cannot be undone.'
          : 'Are you sure you want to delete this record? This cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (isMultipleDelete) {
                  // Sort indices in descending order to avoid index shifting
                  final sortedIndices = selectedRecords.toList()..sort((a, b) => b.compareTo(a));
                  final records = await DatabaseHelper.instance.getAllRecords();
                  
                  for (final index in sortedIndices) {
                    records.removeAt(index);
                  }
                  
                  await DatabaseHelper.instance.saveRecords(records);
                  
                  if (!mounted) return;
                  setState(() {
                    selectedRecords.clear();
                    _isSelectionMode = false;
                    loadRecords();
                  });
                } else if (index != null) {
                  final records = await DatabaseHelper.instance.getAllRecords();
                  records.removeAt(index);
                  await DatabaseHelper.instance.saveRecords(records);
                  
                  if (!mounted) return;
                  setState(() {
                    loadRecords();
                  });
                }
                
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isMultipleDelete
                      ? '$deleteCount records deleted'
                      : 'Record deleted'
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting record(s): $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete all scouting records. This action cannot be undone.\n\n'
          'Make sure you have exported your data if you want to keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              try {
                await DatabaseHelper.instance.deleteAllRecords();
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _records.clear();
                    selectedRecords.clear();
                    _isSelectionMode = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting data: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Delete All',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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

class TeamNumberSelector extends StatelessWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;

  const TeamNumberSelector({
    Key? key,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        int? selected = await showDialog<int>(
          context: context,
          builder: (context) => TeamNumberSelectorDialog(
            initialValue: initialValue,
            onValueChanged: (value) {
              // This callback fires immediately when digits change.
              // (No extra action needed here.)
            },
          ),
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
      child: Text(initialValue.toString()),
    );
  }
}

// --- New stub for TeamNumberSelectorDialog ---
class TeamNumberSelectorDialog extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onValueChanged;

  const TeamNumberSelectorDialog({
    Key? key,
    required this.initialValue,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  _TeamNumberSelectorDialogState createState() => _TeamNumberSelectorDialogState();
}

class _TeamNumberSelectorDialogState extends State<TeamNumberSelectorDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Team Number"),
      content: Text("Team number selection dialog placeholder."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(widget.initialValue),
          child: Text("OK"),
        ),
      ],
    );
  }
}
