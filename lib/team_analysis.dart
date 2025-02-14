import 'package:flutter/material.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'comparison.dart';
import 'dart:math' show max, min;

class TeamStats {
  final int teamNumber;
  final List<ScoutingRecord> records;

  TeamStats({
    required this.teamNumber,
    required this.records,
  });

  // Scoring metrics
  double get avgAutoAlgae => _average((r) => r.algaeRemoved);
  double get avgTeleopAlgae => _average((r) => r.algaeScoredInNet);
  double get avgProcessedAlgae => _average((r) => r.processedAlgaeScored);
  double get avgCycles => _average((r) => r.processorCycles);
  
  // Auto metrics
  double get taxisSuccessRate => _successRate((r) => r.taxis);
  double get autoCoralSuccessRate => _successRate((r) => r.coralPlaced != 'No');
  
  // Endgame metrics
  double get cageHangSuccessRate => _successRate((r) => r.cageHang != 'None');
  double get bargeReturnRate => _successRate((r) => r.returnedToBarge);
  
  // Reliability metrics
  double get breakdownRate => _successRate((r) => r.breakdown);
  
  // Ranking point metrics
  double get autoRankingPointRate => _successRate((r) => r.rankingPoint);
  double get coralRankingPointRate => _successRate((r) => r.coralRankingPoint);
  double get bargeRankingPointRate => _successRate((r) => r.bargeRankingPoint);

  // Overall scoring potential (out of 100)
  double get scoringPotential {
    double score = 0;
    
    // Auto scoring (30 points max)
    score += (avgAutoAlgae / 5) * 15; // Up to 15 points for auto algae
    score += autoCoralSuccessRate * 0.15; // Up to 15 points for auto coral
    
    // Teleop scoring (40 points max)
    score += (avgTeleopAlgae / 10) * 20; // Up to 20 points for teleop algae
    score += (avgProcessedAlgae / 5) * 10; // Up to 10 points for processed algae
    score += (avgCycles / 4) * 10; // Up to 10 points for cycling
    
    // Endgame (30 points max)
    score += cageHangSuccessRate * 0.2; // Up to 20 points for hanging
    score += bargeReturnRate * 0.1; // Up to 10 points for barge return
    
    // Reliability penalty
    score *= (1 - (breakdownRate * 0.5)); // Up to 50% penalty for breakdowns
    
    return max(0, min(score, 100));
  }

  // Helper methods
  double _average(num Function(ScoutingRecord) selector) {
    if (records.isEmpty) return 0;
    return records.map(selector).reduce((a, b) => a + b) / records.length;
  }

  double _successRate(bool Function(ScoutingRecord) selector) {
    if (records.isEmpty) return 0;
    return records.where(selector).length / records.length;
  }

  List<String> getStrengths() {
    List<String> strengths = [];
    
    if (avgAutoAlgae >= 3) strengths.add('Strong Auto Scoring');
    if (taxisSuccessRate >= 0.8) strengths.add('Reliable Taxis');
    if (autoCoralSuccessRate >= 0.7) strengths.add('Consistent Auto Coral');
    if (avgTeleopAlgae >= 8) strengths.add('High Algae Output');
    if (avgProcessedAlgae >= 4) strengths.add('Efficient Processing');
    if (avgCycles >= 3) strengths.add('Fast Cycling');
    if (cageHangSuccessRate >= 0.8) strengths.add('Reliable Hanging');
    if (records.every((r) => !r.breakdown)) strengths.add('No Breakdowns');
    
    return strengths.take(4).toList(); // Limit to top 4 strengths
  }

  List<String> getWeaknesses() {
    List<String> weaknesses = [];
    
    if (avgAutoAlgae < 1) weaknesses.add('Poor Auto Scoring');
    if (taxisSuccessRate < 0.5) weaknesses.add('Inconsistent Taxis');
    if (avgTeleopAlgae < 3) weaknesses.add('Low Scoring Output');
    if (avgProcessedAlgae < 1) weaknesses.add('Minimal Processing');
    if (avgCycles < 1) weaknesses.add('Slow Cycling');
    if (cageHangSuccessRate < 0.3) weaknesses.add('Unreliable Hanging');
    if (breakdownRate >= 0.3) weaknesses.add('Frequent Breakdowns');
    
    return weaknesses.take(3).toList(); // Limit to top 3 weaknesses
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

    // Convert to list of TeamStats and sort by scoring potential
    final teamStats = teamRecords.entries
        .map((e) => TeamStats(teamNumber: e.key, records: e.value))
        .toList()
      ..sort((a, b) => b.scoringPotential.compareTo(a.scoringPotential));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Analysis'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: teamStats.length,
        itemBuilder: (context, index) => TeamAnalysisCard(stats: teamStats[index]),
      ),
    );
  }
}

class TeamAnalysisCard extends StatelessWidget {
  final TeamStats stats;

  const TeamAnalysisCard({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 0 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComparisonPage(records: stats.records),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with team number and scoring potential
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team ${stats.teamNumber}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${stats.records.length} matches scouted',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _buildScoreIndicator(context, stats.scoringPotential),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key metrics
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Auto Algae',
                          value: stats.avgAutoAlgae.toStringAsFixed(1),
                        ),
                      ),
                      Expanded(
                        child: _MetricTile(
                          label: 'Teleop Algae',
                          value: stats.avgTeleopAlgae.toStringAsFixed(1),
                        ),
                      ),
                      Expanded(
                        child: _MetricTile(
                          label: 'Cycles',
                          value: stats.avgCycles.toStringAsFixed(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Success rates
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Hang Rate',
                          value: '${(stats.cageHangSuccessRate * 100).round()}%',
                          color: _getSuccessRateColor(context, stats.cageHangSuccessRate),
                        ),
                      ),
                      Expanded(
                        child: _MetricTile(
                          label: 'Taxis Rate',
                          value: '${(stats.taxisSuccessRate * 100).round()}%',
                          color: _getSuccessRateColor(context, stats.taxisSuccessRate),
                        ),
                      ),
                      Expanded(
                        child: _MetricTile(
                          label: 'Breakdown',
                          value: '${(stats.breakdownRate * 100).round()}%',
                          color: _getBreakdownColor(context, stats.breakdownRate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Strengths and weaknesses
                  if (stats.getStrengths().isNotEmpty) ...[
                    _buildStrengthsSection(context, stats.getStrengths()),
                    const SizedBox(height: 8),
                  ],
                  if (stats.getWeaknesses().isNotEmpty)
                    _buildWeaknessesSection(context, stats.getWeaknesses()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(BuildContext context, double score) {
    final color = score >= 80 ? Colors.green :
                 score >= 60 ? Colors.blue :
                 score >= 40 ? Colors.orange :
                 Colors.red;
                 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            score.round().toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsSection(BuildContext context, List<String> strengths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STRENGTHS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: strengths.map((strength) => Chip(
            label: Text(
              strength,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
              ),
            ),
            backgroundColor: Colors.green.withOpacity(0.1),
            side: BorderSide(color: Colors.green.withOpacity(0.2)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildWeaknessesSection(BuildContext context, List<String> weaknesses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WEAKNESSES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: weaknesses.map((weakness) => Chip(
            label: Text(
              weakness,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
            backgroundColor: Colors.red.withOpacity(0.1),
            side: BorderSide(color: Colors.red.withOpacity(0.2)),
          )).toList(),
        ),
      ],
    );
  }

  Color _getSuccessRateColor(BuildContext context, double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.blue;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getBreakdownColor(BuildContext context, double rate) {
    if (rate <= 0.1) return Colors.green;
    if (rate <= 0.2) return Colors.orange;
    return Colors.red;
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MetricTile({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}