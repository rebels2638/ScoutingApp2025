import 'package:flutter/material.dart';
import 'data.dart';

class TeamStats {
  final int teamNumber;
  final List<ScoutingRecord> matches;
  final int totalMatches;
  final double avgAlgaeScored;
  final double avgProcessedAlgae;
  final double avgProcessorCycles;
  final double autoSuccessRate;
  final double teleopSuccessRate;
  final double rankingPointRate;
  final List<bool> breakdownHistory;
  final List<int> scoringTrend;

  TeamStats({
    required this.teamNumber,
    required this.matches,
  })  : totalMatches = matches.length,
        avgAlgaeScored = matches.map((m) => m.algaeScoredInNet).reduce((a, b) => a + b) / matches.length,
        avgProcessedAlgae = matches.map((m) => m.processedAlgaeScored).reduce((a, b) => a + b) / matches.length,
        avgProcessorCycles = matches.map((m) => m.processorCycles).reduce((a, b) => a + b) / matches.length,
        autoSuccessRate = matches.where((m) => m.rankingPoint).length / matches.length * 100,
        teleopSuccessRate = matches.where((m) => m.coralRankingPoint).length / matches.length * 100,
        rankingPointRate = matches.where((m) => m.bargeRankingPoint).length / matches.length * 100,
        breakdownHistory = matches.map((m) => m.breakdown).toList(),
        scoringTrend = matches.map((m) => m.algaeScoredInNet + m.processedAlgaeScored).toList();

  String get reliability => 
      (breakdownHistory.where((b) => !b).length / breakdownHistory.length * 100).toStringAsFixed(1) + '%';

  List<String> getStrengths() {
    List<String> strengths = [];
    if (avgAlgaeScored > 5) strengths.add('High Algae Scoring');
    if (avgProcessedAlgae > 3) strengths.add('Efficient Processing');
    if (avgProcessorCycles > 2) strengths.add('Good Cycling');
    if (autoSuccessRate > 75) strengths.add('Strong Auto');
    if (teleopSuccessRate > 75) strengths.add('Strong Teleop');
    if (rankingPointRate > 50) strengths.add('Consistent Endgame');
    if (breakdownHistory.where((b) => !b).length / breakdownHistory.length > 0.9) {
      strengths.add('High Reliability');
    }
    return strengths;
  }

  List<String> getWeaknesses() {
    List<String> weaknesses = [];
    if (avgAlgaeScored < 2) weaknesses.add('Low Scoring');
    if (avgProcessedAlgae < 1) weaknesses.add('Inefficient Processing');
    if (avgProcessorCycles < 1) weaknesses.add('Poor Cycling');
    if (autoSuccessRate < 25) weaknesses.add('Weak Auto');
    if (teleopSuccessRate < 25) weaknesses.add('Weak Teleop');
    if (rankingPointRate < 25) weaknesses.add('Inconsistent Endgame');
    if (breakdownHistory.where((b) => b).length / breakdownHistory.length > 0.2) {
      weaknesses.add('Frequent Breakdowns');
    }
    return weaknesses;
  }
}

class TeamAnalysisPage extends StatelessWidget {
  final List<ScoutingRecord> allRecords;

  const TeamAnalysisPage({Key? key, required this.allRecords}) : super(key: key);

  Map<int, List<ScoutingRecord>> _groupByTeam() {
    Map<int, List<ScoutingRecord>> teams = {};
    for (var record in allRecords) {
      teams.putIfAbsent(record.teamNumber, () => []).add(record);
    }
    return teams;
  }

  List<TeamStats> _getTeamStats() {
    var teams = _groupByTeam();
    return teams.entries
        .map((e) => TeamStats(teamNumber: e.key, matches: e.value))
        .toList()
      ..sort((a, b) => b.avgAlgaeScored.compareTo(a.avgAlgaeScored));
  }

  Widget _buildTrendGraph(List<int> trend) {
    return Container(
      height: 100,
      child: Row(
        children: trend.asMap().entries.map((entry) {
          return Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.6),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    height: entry.value.toDouble() * 5,
                  ),
                ),
                Text(
                  (entry.key + 1).toString(),
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamStats = _getTeamStats();

    return Scaffold(
      appBar: AppBar(
        title: Text('Team Analysis'),
      ),
      body: ListView.builder(
        itemCount: teamStats.length,
        itemBuilder: (context, index) {
          final stats = teamStats[index];
          return ExpansionTile(
            title: Text('Team ${stats.teamNumber}'),
            subtitle: Text('${stats.totalMatches} matches, ${stats.reliability} reliability'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scoring Trend', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    _buildTrendGraph(stats.scoringTrend),
                    SizedBox(height: 16),
                    Text('Performance Stats:', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    Table(
                      columnWidths: {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(children: [
                          Text('Avg Algae Scored'),
                          Text('${stats.avgAlgaeScored.toStringAsFixed(1)}'),
                        ]),
                        TableRow(children: [
                          Text('Avg Processed Algae'),
                          Text('${stats.avgProcessedAlgae.toStringAsFixed(1)}'),
                        ]),
                        TableRow(children: [
                          Text('Avg Processor Cycles'),
                          Text('${stats.avgProcessorCycles.toStringAsFixed(1)}'),
                        ]),
                        TableRow(children: [
                          Text('Auto Success Rate'),
                          Text('${stats.autoSuccessRate.toStringAsFixed(1)}%'),
                        ]),
                        TableRow(children: [
                          Text('Teleop Success Rate'),
                          Text('${stats.teleopSuccessRate.toStringAsFixed(1)}%'),
                        ]),
                        TableRow(children: [
                          Text('Ranking Point Rate'),
                          Text('${stats.rankingPointRate.toStringAsFixed(1)}%'),
                        ]),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (stats.getStrengths().isNotEmpty) ...[
                      Text('Strengths:', style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: stats.getStrengths().map((s) => Chip(
                          label: Text(
                            s,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.black 
                                  : null,
                            ),
                          ),
                          backgroundColor: Colors.green.shade100,
                          side: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.black 
                                : Colors.transparent,
                          ),
                        )).toList(),
                      ),
                      SizedBox(height: 16),
                    ],
                    if (stats.getWeaknesses().isNotEmpty) ...[
                      Text('Areas for Improvement:', style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: stats.getWeaknesses().map((w) => Chip(
                          label: Text(
                            w,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.black 
                                  : null,
                            ),
                          ),
                          backgroundColor: Colors.red.shade100,
                          side: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.black 
                                : Colors.transparent,
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}