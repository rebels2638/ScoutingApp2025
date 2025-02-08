import 'package:flutter/material.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'comparison.dart';

class TeamStats {
  final int teamNumber;
  final List<ScoutingRecord> records;

  TeamStats({
    required this.teamNumber,
    required this.records,
  });

  double getAverage(num Function(ScoutingRecord) selector) {
    if (records.isEmpty) return 0;
    return records.map(selector).reduce((a, b) => a + b) / records.length;
  }

  String formatAverage(num Function(ScoutingRecord) selector) {
    double avg = getAverage(selector);
    if (avg == 0) return '0.0';
    return '${avg.toStringAsFixed(1)}${records.length > 1 ? ' avg' : ''}';
  }

  String formatBreakdownRate() {
    if (records.isEmpty) return '0/0 - 0%';
    int breakdowns = records.where((r) => r.breakdown).length;
    return '${breakdowns}/${records.length} - ${(breakdowns/records.length * 100).round()}%';
  }

  String formatCageHangStats() {
    if (records.isEmpty) return '0/0 - 0%';
    int successful = records.where((r) => r.cageHang != 'None').length;
    return '${successful}/${records.length} - ${(successful/records.length * 100).round()}%';
  }

  List<String> getStrengths() {
    List<String> strengths = [];
    if (getAverage((r) => r.algaeScoredInNet) > 5) strengths.add('High Algae Scoring');
    if (getAverage((r) => r.processedAlgaeScored) > 3) strengths.add('Efficient Processing');
    if (getAverage((r) => r.processorCycles) > 2) strengths.add('Good Cycling');
    if (getAverage((r) => r.autoAlgaeInNet) > 2) strengths.add('Strong Auto Scoring');
    if (getAverage((r) => r.autoAlgaeInProcessor) > 1) strengths.add('Good Auto Processing');
    return strengths;
  }

  List<String> getWeaknesses() {
    List<String> weaknesses = [];
    if (getAverage((r) => r.algaeScoredInNet) < 2) weaknesses.add('Low Scoring');
    if (getAverage((r) => r.processedAlgaeScored) < 1) weaknesses.add('Inefficient Processing');
    if (getAverage((r) => r.processorCycles) < 1) weaknesses.add('Poor Cycling');
    if (getAverage((r) => r.autoAlgaeInNet) < 1) weaknesses.add('Weak Auto Scoring');
    if (getAverage((r) => r.autoAlgaeInProcessor) < 1) weaknesses.add('Poor Auto Processing');
    return weaknesses;
  }
}

class TeamAnalysisPage extends StatelessWidget {
  final List<ScoutingRecord> records;

  const TeamAnalysisPage({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group records by team
    Map<int, List<ScoutingRecord>> teamRecords = {};
    for (var record in records) {
      teamRecords.putIfAbsent(record.teamNumber, () => []).add(record);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Analysis'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: teamRecords.length,
        itemBuilder: (context, index) {
          final entry = teamRecords.entries.elementAt(index);
          final teamStats = TeamStats(
            teamNumber: entry.key,
            records: entry.value,
          );

          return Card(
            child: ListTile(
              title: Text('Team ${entry.key}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Matches: ${entry.value.length}'),
                  Text('Avg Auto Algae: ${teamStats.formatAverage((r) => r.algaeRemoved)}'),
                  Text('Avg Teleop Algae: ${teamStats.formatAverage((r) => r.algaeScoredInNet)}'),
                  Text('Breakdown Rate: ${teamStats.formatBreakdownRate()}'),
                  Text('Cage Hang Success: ${teamStats.formatCageHangStats()}'),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComparisonPage(records: entry.value),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}