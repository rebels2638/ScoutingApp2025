import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoutingRecord {
  final String timestamp;
  final int matchNumber;
  final String matchType;
  final int teamNumber;
  final bool isRedAlliance;
  
  // Autonomous
  final String cageType;
  final bool coralPreloaded;
  final bool taxis;
  final int algaeRemoved;
  final String coralPlaced;
  final bool rankingPoint;
  final bool canPickupAlgae;
  
  // Teleop
  final int algaeScoredInNet;
  final bool coralRankingPoint;
  final int algaeProcessed;
  final int processedAlgaeScored;
  final int processorCycles;
  final bool coOpPoint;
  
  // Endgame
  final bool returnedToBarge;
  final String cageHang;
  final bool bargeRankingPoint;
  
  // Other
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
  });

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
    timestamp: json['timestamp'],
    matchNumber: json['matchNumber'],
    matchType: json['matchType'],
    teamNumber: json['teamNumber'],
    isRedAlliance: json['isRedAlliance'],
    cageType: json['cageType'],
    coralPreloaded: json['coralPreloaded'],
    taxis: json['taxis'],
    algaeRemoved: json['algaeRemoved'],
    coralPlaced: json['coralPlaced'],
    rankingPoint: json['rankingPoint'],
    canPickupAlgae: json['canPickupAlgae'],
    algaeScoredInNet: json['algaeScoredInNet'],
    coralRankingPoint: json['coralRankingPoint'],
    algaeProcessed: json['algaeProcessed'],
    processedAlgaeScored: json['processedAlgaeScored'],
    processorCycles: json['processorCycles'],
    coOpPoint: json['coOpPoint'],
    returnedToBarge: json['returnedToBarge'],
    cageHang: json['cageHang'],
    bargeRankingPoint: json['bargeRankingPoint'],
    breakdown: json['breakdown'],
    comments: json['comments'],
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
}

class DataPage extends StatefulWidget {
  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List<ScoutingRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await DataManager.getRecords();
    setState(() {
      _records = records;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _records.isEmpty
          ? Center(child: Text('No scouting records available'))
          : ListView.builder(
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('Match ${record.matchNumber} - Team ${record.teamNumber}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${record.matchType} - ${record.timestamp}'),
                        Text('Alliance: ${record.isRedAlliance ? "Red" : "Blue"}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        await DataManager.deleteRecord(index);
                        _loadRecords();
                      },
                    ),
                    onTap: () {
                      _showRecordDetails(record);
                    },
                  ),
                );
              },
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
                'Can Pickup Algae: ${record.canPickupAlgae ? "Yes" : "No"}',
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
