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

  // auto metrics
  double get autoTaxisRate => _successRate((r) => r.autoTaxis);
  double get autoAlgaeAvg => _average((r) => r.autoAlgaeRemoved);
  double get autoAlgaeNetAvg => _average((r) => r.autoAlgaeInNet);
  double get autoAlgaeProcessorAvg => _average((r) => r.autoAlgaeInProcessor);
  
  // auto coral success rates
  double get autoL4SuccessRate => _successRateWithAttempts(
    (r) => r.autoCoralHeight4Success,
    (r) => r.autoCoralHeight4Success + r.autoCoralHeight4Failure
  );
  double get autoL3SuccessRate => _successRateWithAttempts(
    (r) => r.autoCoralHeight3Success,
    (r) => r.autoCoralHeight3Success + r.autoCoralHeight3Failure
  );
  double get autoL2SuccessRate => _successRateWithAttempts(
    (r) => r.autoCoralHeight2Success,
    (r) => r.autoCoralHeight2Success + r.autoCoralHeight2Failure
  );
  double get autoL1SuccessRate => _successRateWithAttempts(
    (r) => r.autoCoralHeight1Success,
    (r) => r.autoCoralHeight1Success + r.autoCoralHeight1Failure
  );
  
  // auto coral averages
  double get autoL4Avg => _average((r) => r.autoCoralHeight4Success);
  double get autoL3Avg => _average((r) => r.autoCoralHeight3Success);
  double get autoL2Avg => _average((r) => r.autoCoralHeight2Success);
  double get autoL1Avg => _average((r) => r.autoCoralHeight1Success);

  // teleop metrics
  double get teleopAlgaeNetAvg => _average((r) => r.teleopAlgaeScoredInNet);
  double get teleopAlgaeProcessedAvg => _average((r) => r.teleopAlgaeProcessed);
  double get teleopAlgaeProcessorAttemptsAvg => _average((r) => r.teleopAlgaeProcessorAttempts);
  double get processorEfficiency => teleopAlgaeProcessedAvg / (teleopAlgaeProcessorAttemptsAvg > 0 ? teleopAlgaeProcessorAttemptsAvg : 1);
  
  // teleop coral success rates
  double get teleopL4SuccessRate => _successRateWithAttempts(
    (r) => r.teleopCoralHeight4Success,
    (r) => r.teleopCoralHeight4Success + r.teleopCoralHeight4Failure
  );
  double get teleopL3SuccessRate => _successRateWithAttempts(
    (r) => r.teleopCoralHeight3Success,
    (r) => r.teleopCoralHeight3Success + r.teleopCoralHeight3Failure
  );
  double get teleopL2SuccessRate => _successRateWithAttempts(
    (r) => r.teleopCoralHeight2Success,
    (r) => r.teleopCoralHeight2Success + r.teleopCoralHeight2Failure
  );
  double get teleopL1SuccessRate => _successRateWithAttempts(
    (r) => r.teleopCoralHeight1Success,
    (r) => r.teleopCoralHeight1Success + r.teleopCoralHeight1Failure
  );
  
  // teleop coral averages
  double get teleopL4Avg => _average((r) => r.teleopCoralHeight4Success);
  double get teleopL3Avg => _average((r) => r.teleopCoralHeight3Success);
  double get teleopL2Avg => _average((r) => r.teleopCoralHeight2Success);
  double get teleopL1Avg => _average((r) => r.teleopCoralHeight1Success);

  // endgame metrics
  double get cageHangSuccessRate => _successRate((r) => r.endgameCageHang != 'None');
  double get bargeReturnRate => _successRate((r) => r.endgameReturnedToBarge);
  double get bargeRankingPointRate => _successRate((r) => r.endgameBargeRankingPoint);
  
  // ranking point metrics
  double get coralRankingPointRate => _successRate((r) => r.teleopCoralRankingPoint);
  double get coOpPointRate => _successRate((r) => r.otherCoOpPoint);
  
  // reliability metrics
  double get breakdownRate => _successRate((r) => r.otherBreakdown);
  String get preferredCoralPickupMethod => _mostCommonValue(records.map((r) => r.teleopCoralPickupMethod));

  // overall scoring potential (out of 100)
  double get scoringPotential {
    double score = 0;
    
    // auto scoring (30 points max)
    score += (autoAlgaeAvg / 5) * 10; // Up to 10 points for auto algae
    score += ((autoL4SuccessRate + autoL3SuccessRate + autoL2SuccessRate + autoL1SuccessRate) / 4) * 20; // Up to 20 points for auto coral success rates
    
    // teleop scoring (40 points max)
    score += (teleopAlgaeNetAvg / 10) * 15; // Up to 15 points for teleop algae in net
    score += (teleopAlgaeProcessedAvg / 5) * 10; // Up to 10 points for processed algae
    score += ((teleopL4SuccessRate + teleopL3SuccessRate + teleopL2SuccessRate + teleopL1SuccessRate) / 4) * 15; // Up to 15 points for teleop coral success rates
    
    // endgame (30 points max)
    score += cageHangSuccessRate * 15; // Up to 15 points for hanging
    score += bargeReturnRate * 10; // Up to 10 points for barge return
    score += bargeRankingPointRate * 5; // Up to 5 points for barge ranking points
    
    // reliability penalty
    score *= (1 - (breakdownRate * 0.5)); // Up to 50% penalty for breakdowns
    
    return max(0, min(score, 100));
  }

  // Overall success rates
  double get autoOverallSuccessRate {
    int totalSuccesses = records.map((r) => 
      r.autoCoralHeight4Success + 
      r.autoCoralHeight3Success + 
      r.autoCoralHeight2Success + 
      r.autoCoralHeight1Success
    ).reduce((a, b) => a + b);
    
    int totalAttempts = records.map((r) => 
      r.autoCoralHeight4Success + r.autoCoralHeight4Failure +
      r.autoCoralHeight3Success + r.autoCoralHeight3Failure +
      r.autoCoralHeight2Success + r.autoCoralHeight2Failure +
      r.autoCoralHeight1Success + r.autoCoralHeight1Failure
    ).reduce((a, b) => a + b);
    
    return totalAttempts > 0 ? totalSuccesses / totalAttempts : 0;
  }

  double get teleopOverallSuccessRate {
    int totalSuccesses = records.map((r) => 
      r.teleopCoralHeight4Success + 
      r.teleopCoralHeight3Success + 
      r.teleopCoralHeight2Success + 
      r.teleopCoralHeight1Success
    ).reduce((a, b) => a + b);
    
    int totalAttempts = records.map((r) => 
      r.teleopCoralHeight4Success + r.teleopCoralHeight4Failure +
      r.teleopCoralHeight3Success + r.teleopCoralHeight3Failure +
      r.teleopCoralHeight2Success + r.teleopCoralHeight2Failure +
      r.teleopCoralHeight1Success + r.teleopCoralHeight1Failure
    ).reduce((a, b) => a + b);
    
    return totalAttempts > 0 ? totalSuccesses / totalAttempts : 0;
  }

  // total coral averages
  double get autoTotalCoralAvg {
    if (records.isEmpty) return 0;
    return records.map((r) => 
      r.autoCoralHeight4Success + 
      r.autoCoralHeight3Success + 
      r.autoCoralHeight2Success + 
      r.autoCoralHeight1Success
    ).reduce((a, b) => a + b) / records.length;
  }

  double get teleopTotalCoralAvg {
    if (records.isEmpty) return 0;
    return records.map((r) => 
      r.teleopCoralHeight4Success + 
      r.teleopCoralHeight3Success + 
      r.teleopCoralHeight2Success + 
      r.teleopCoralHeight1Success
    ).reduce((a, b) => a + b) / records.length;
  }

  // helper methods
  double _average(num Function(ScoutingRecord) selector) {
    if (records.isEmpty) return 0;
    return records.map(selector).reduce((a, b) => a + b) / records.length;
  }

  double _successRate(bool Function(ScoutingRecord) selector) {
    if (records.isEmpty) return 0;
    return records.where(selector).length / records.length;
  }

  double _successRateWithAttempts(
    int Function(ScoutingRecord) successSelector,
    int Function(ScoutingRecord) totalAttemptsSelector
  ) {
    if (records.isEmpty) return 0;
    int totalSuccesses = records.map(successSelector).reduce((a, b) => a + b);
    int totalAttempts = records.map(totalAttemptsSelector).reduce((a, b) => a + b);
    return totalAttempts > 0 ? totalSuccesses / totalAttempts : 0;
  }

  String _mostCommonValue(Iterable<String> values) {
    if (values.isEmpty) return 'None';
    Map<String, int> counts = {};
    for (var value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<String> getStrengths() {
    List<String> strengths = [];
    
    // auto strengths
    if (autoTaxisRate >= 0.8) strengths.add('Reliable Auto Taxis');
    if (autoAlgaeAvg >= 3) strengths.add('Strong Auto Algae');
    if (autoL4SuccessRate >= 0.7) strengths.add('Accurate L4 Auto');
    if ((autoL4Avg + autoL3Avg + autoL2Avg + autoL1Avg) >= 3) strengths.add('High Auto Coral Output');
    
    // teleop strengths
    if (teleopAlgaeNetAvg >= 8) strengths.add('High Algae Output');
    if (processorEfficiency >= 0.8) strengths.add('Efficient Processor');
    if (teleopL4SuccessRate >= 0.7) strengths.add('Accurate L4 Scoring');
    if ((teleopL4Avg + teleopL3Avg + teleopL2Avg + teleopL1Avg) >= 5) strengths.add('High Coral Output');
    
    // endgame strengths
    if (cageHangSuccessRate >= 0.8) strengths.add('Reliable Hanging');
    if (bargeReturnRate >= 0.8) strengths.add('Consistent Barge Return');
    
    // ranking point strengths
    if (coralRankingPointRate >= 0.5) strengths.add('Frequent Coral RP');
    if (bargeRankingPointRate >= 0.5) strengths.add('Frequent Barge RP');
    if (coOpPointRate >= 0.5) strengths.add('Good Co-op Partner');
    
    // reliability strength
    if (breakdownRate <= 0.1) strengths.add('Very Reliable');
    
    return strengths.take(4).toList(); // Limit to top 4 strengths
  }

  List<String> getWeaknesses() {
    List<String> weaknesses = [];
    
    // auto weaknesses
    if (autoTaxisRate < 0.5) weaknesses.add('Unreliable Auto Taxis');
    if (autoAlgaeAvg < 1) weaknesses.add('Poor Auto Algae');
    if (autoL4SuccessRate < 0.3 && autoL4Avg > 0) weaknesses.add('Inaccurate L4 Auto');
    if ((autoL4Avg + autoL3Avg + autoL2Avg + autoL1Avg) < 1) weaknesses.add('Low Auto Coral Output');
    
    // teleop weaknesses
    if (teleopAlgaeNetAvg < 3) weaknesses.add('Low Algae Output');
    if (processorEfficiency < 0.5 && teleopAlgaeProcessorAttemptsAvg > 0) weaknesses.add('Inefficient Processing');
    if (teleopL4SuccessRate < 0.3 && teleopL4Avg > 0) weaknesses.add('Inaccurate L4 Scoring');
    if ((teleopL4Avg + teleopL3Avg + teleopL2Avg + teleopL1Avg) < 2) weaknesses.add('Low Coral Output');
    
    // endgame weaknesses
    if (cageHangSuccessRate < 0.3) weaknesses.add('Unreliable Hanging');
    if (bargeReturnRate < 0.3) weaknesses.add('Rare Barge Return');
    
    // reliability weakness
    if (breakdownRate >= 0.3) weaknesses.add('Frequent Breakdowns');
    
    return weaknesses.take(3).toList(); // limit to top 3 weaknesses
  }
}

class TeamAnalysisPage extends StatefulWidget {
  final List<ScoutingRecord> records;

  const TeamAnalysisPage({Key? key, required this.records}) : super(key: key);

  @override
  TeamAnalysisPageState createState() => TeamAnalysisPageState();
}

class TeamAnalysisPageState extends State<TeamAnalysisPage> {
  String _searchQuery = '';
  Set<int> _expandedTeams = {};
  late List<TeamStats> _teamStats;

  @override
  void initState() {
    super.initState();
    _initializeTeamStats();
  }

  void _initializeTeamStats() {
    // group records by team
    Map<int, List<ScoutingRecord>> teamRecords = {};
    for (var record in widget.records) {
      teamRecords.putIfAbsent(record.teamNumber, () => []).add(record);
    }

    // convert to list of TeamStats and sort by scoring potential
    _teamStats = teamRecords.entries
        .map((e) => TeamStats(teamNumber: e.key, records: e.value))
        .toList()
      ..sort((a, b) => b.scoringPotential.compareTo(a.scoringPotential));
  }

  void _toggleExpanded(int teamNumber) {
    setState(() {
      if (_expandedTeams.contains(teamNumber)) {
        _expandedTeams.remove(teamNumber);
      } else {
        _expandedTeams.add(teamNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeams = _teamStats.where((stats) {
      if (_searchQuery.isEmpty) return true;
      return stats.teamNumber.toString().contains(_searchQuery);
    }).toList();

    return Scaffold(
      /*
      appBar: AppBar(
        title: const Text('Team Analysis'),
      ),
      */
      body: Column(
        children: [
          // search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search teams...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // team list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: filteredTeams.length,
              itemBuilder: (context, index) {
                final stats = filteredTeams[index];
                final isExpanded = _expandedTeams.contains(stats.teamNumber);
                
                return Card(
                  elevation: isExpanded ? 2 : 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      // header (always visible)
                      InkWell(
                        onTap: () => _toggleExpanded(stats.teamNumber),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // expanded content
                      if (isExpanded)
                        TeamAnalysisCard(stats: stats),
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
}

class TeamAnalysisCard extends StatefulWidget {
  final TeamStats stats;

  const TeamAnalysisCard({Key? key, required this.stats}) : super(key: key);

  @override
  State<TeamAnalysisCard> createState() => _TeamAnalysisCardState();
}

class _TeamAnalysisCardState extends State<TeamAnalysisCard> {
  final Set<String> _expandedSections = {};
  final List<String> _allSections = ['auto', 'teleop', 'endgame', 'capabilities & analysis'];
  bool _allExpanded = false;

  void _toggleSection(String section) {
    setState(() {
      if (_expandedSections.contains(section)) {
        _expandedSections.remove(section);
      } else {
        _expandedSections.add(section);
      }
      _updateAllExpandedState();
    });
  }

  void _toggleAllSections() {
    setState(() {
      if (_allExpanded) {
        _expandedSections.clear();
      } else {
        _expandedSections.addAll(_allSections);
      }
      _allExpanded = !_allExpanded;
    });
  }

  void _updateAllExpandedState() {
    _allExpanded = _allSections.every((section) => _expandedSections.contains(section));
  }

  Widget _buildCollapsibleSection(BuildContext context, String title, List<Widget> content) {
    final isExpanded = _expandedSections.contains(title);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _toggleSection(title),
          child: Padding(
            padding: const EdgeInsets.only(top: 1, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...content,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // expand all button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _toggleAllSections,
              label: Text(_allExpanded ? 'Collapse All' : 'Expand All'),
              icon: Icon(
                _allExpanded ? Icons.unfold_less : Icons.unfold_more,
                size: 20,
              ),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // auto performance
          _buildCollapsibleSection(
            context,
            'auto',
            [
              // auto coral success rates
              _buildSectionSubheader(context, 'Coral Success Rates'),
              _buildMetricGrid(context, [
                _MetricTile(
                  label: 'Overall Success Rate',
                  value: '${(widget.stats.autoOverallSuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.autoOverallSuccessRate),
                ),
                _MetricTile(
                  label: 'L4 Rate',
                  value: '${(widget.stats.autoL4SuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.autoL4SuccessRate),
                ),
                _MetricTile(
                  label: 'L3 Rate',
                  value: '${(widget.stats.autoL3SuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.autoL3SuccessRate),
                ),
                _MetricTile(
                  label: 'L2 Rate',
                  value: '${(widget.stats.autoL2SuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.autoL2SuccessRate),
                ),
                _MetricTile(
                  label: 'L1 Rate',
                  value: '${(widget.stats.autoL1SuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.autoL1SuccessRate),
                ),
              ]),

              // auto coral averages
              _buildSectionSubheader(context, 'Coral Averages'),
              _buildMetricGrid(context, [
                _MetricTile(
                  label: 'Total Avg',
                  value: widget.stats.autoTotalCoralAvg.toStringAsFixed(1),
                  color: widget.stats.autoTotalCoralAvg >= 2 ? Colors.green : 
                         widget.stats.autoTotalCoralAvg >= 1 ? Colors.blue : null,
                ),
                _MetricTile(
                  label: 'L4 Avg',
                  value: widget.stats.autoL4Avg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'L3 Avg',
                  value: widget.stats.autoL3Avg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'L2 Avg',
                  value: widget.stats.autoL2Avg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'L1 Avg',
                  value: widget.stats.autoL1Avg.toStringAsFixed(1),
                ),
              ]),

              // auto algae
              _buildSectionSubheader(context, 'Algae'),
              _buildMetricGrid(context, [
                _MetricTile(
                  label: 'Taxis Rate',
                  value: '${(widget.stats.autoTaxisRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.autoTaxisRate),
                ),
                _MetricTile(
                  label: 'Auto Algae',
                  value: widget.stats.autoAlgaeAvg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'Net Algae',
                  value: widget.stats.autoAlgaeNetAvg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'Processor',
                  value: widget.stats.autoAlgaeProcessorAvg.toStringAsFixed(1),
                ),
              ]),
            ],
          ),

          // teleop performance
          _buildCollapsibleSection(
            context,
            'teleop',
            [
              // teleop coral success rates
              _buildSectionSubheader(context, 'Coral Success Rates'),
              _buildMetricGrid(context, [
                _MetricTile(
                  label: 'Overall Success Rate',
                  value: '${(widget.stats.teleopOverallSuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.teleopOverallSuccessRate),
                ),
                _MetricTile(
                  label: 'L4 Rate',
                  value: '${(widget.stats.teleopL4SuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.teleopL4SuccessRate),
                ),
                _MetricTile(
                  label: 'L3 Rate',
                  value: '${(widget.stats.teleopL3SuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.teleopL3SuccessRate),
                ),
                _MetricTile(
                  label: 'L2 Rate',
                  value: '${(widget.stats.teleopL2SuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.teleopL2SuccessRate),
                ),
                _MetricTile(
                  label: 'L1 Rate',
                  value: '${(widget.stats.teleopL1SuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.teleopL1SuccessRate),
                ),
              ]),

              // teleop coral averages
              _buildSectionSubheader(context, 'Coral Averages'),
              _buildMetricGrid(context, [
                _MetricTile(
                  label: 'Total Avg',
                  value: widget.stats.teleopTotalCoralAvg.toStringAsFixed(1),
                  color: widget.stats.teleopTotalCoralAvg >= 4 ? Colors.green : 
                         widget.stats.teleopTotalCoralAvg >= 2 ? Colors.blue : null,
                ),
                _MetricTile(
                  label: 'L4 Avg',
                  value: widget.stats.teleopL4Avg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'L3 Avg',
                  value: widget.stats.teleopL3Avg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'L2 Avg',
                  value: widget.stats.teleopL2Avg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'L1 Avg',
                  value: widget.stats.teleopL1Avg.toStringAsFixed(1),
                ),
              ]),

              // teleop algae
              _buildSectionSubheader(context, 'Algae'),
              _buildMetricGrid(context, [
                _MetricTile(
                  label: 'Net Algae',
                  value: widget.stats.teleopAlgaeNetAvg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'Processed',
                  value: widget.stats.teleopAlgaeProcessedAvg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'Attempts',
                  value: widget.stats.teleopAlgaeProcessorAttemptsAvg.toStringAsFixed(1),
                ),
                _MetricTile(
                  label: 'Efficiency',
                  value: '${(widget.stats.processorEfficiency * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.processorEfficiency),
                ),
              ]),
            ],
          ),

          // endgame & ranking points
          _buildCollapsibleSection(
            context,
            'endgame',
            [
              _buildMetricGrid(context, [
                _MetricTile(
                  label: 'Hang Rate',
                  value: '${(widget.stats.cageHangSuccessRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.cageHangSuccessRate),
                ),
                _MetricTile(
                  label: 'Barge Rate',
                  value: '${(widget.stats.bargeReturnRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.bargeReturnRate),
                ),
                _MetricTile(
                  label: 'Coral RP',
                  value: '${(widget.stats.coralRankingPointRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.coralRankingPointRate),
                ),
                _MetricTile(
                  label: 'Co-Op Rate',
                  value: '${(widget.stats.coOpPointRate * 100).round()}%',
                  color: _getSuccessRateColor(context, widget.stats.coOpPointRate),
                ),
              ]),
            ],
          ),

          // capabilities & analysis
          _buildCollapsibleSection(
            context,
            'capabilities & analysis',
            [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Coral Pickup: ${widget.stats.preferredCoralPickupMethod}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (widget.stats.getStrengths().isNotEmpty) ...[
                _buildStrengthsSection(context, widget.stats.getStrengths()),
                const SizedBox(height: 8),
              ],
              if (widget.stats.getWeaknesses().isNotEmpty)
                _buildWeaknessesSection(context, widget.stats.getWeaknesses()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSubheader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context, List<Widget> metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      mainAxisSpacing: 4,
      crossAxisSpacing: 8,
      padding: EdgeInsets.only(bottom: 4),
      children: metrics,
    );
  }

  Color _getSuccessRateColor(BuildContext context, double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.blue;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
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