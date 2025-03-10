import 'package:flutter/material.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'database_helper.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'drawing_page.dart' as drawing;
import 'dart:math' show max;
import 'scouting.dart' show SectionHeader;

// Fallback implementation for LinkedScrollControllerGroup in case it's not available in your Flutter version.
class LinkedScrollControllerGroup {
  final List<ScrollController> _controllers = [];
  bool _isJumping = false;
  bool _isDisposed = false;
  
  ScrollController addAndGetController() {
    final controller = ScrollController();
    if (!_isDisposed) {
      _controllers.add(controller);
      controller.addListener(() {
        if (_isJumping || _isDisposed) return;
        _isJumping = true;
        for (final other in _controllers) {
          if (other == controller || !other.hasClients) continue;
          if ((other.offset - controller.offset).abs() > 1.0) {
            other.jumpTo(controller.offset);
          }
        }
        _isJumping = false;
      });
    }
    return controller;
  }
  
  void dispose() {
    _isDisposed = true;
    // Create a copy of the list to avoid concurrent modification
    final controllersCopy = List<ScrollController>.from(_controllers);
    for (final controller in controllersCopy) {
      if (controller.hasClients) {
        controller.dispose();
      }
    }
    _controllers.clear();
  }
}

class TeamStats {
  final int teamNumber;
  final bool isRedAlliance;
  final List<ScoutingRecord> records;

  TeamStats({
    required this.teamNumber,
    required this.isRedAlliance,
    required this.records,
  });

  double getAverage(num Function(ScoutingRecord) selector) {
    if (records.isEmpty) return 0;
    return records.map(selector).reduce((a, b) => a + b) / records.length;
  }

  double getSuccessRate(bool Function(ScoutingRecord) selector) {
    if (records.isEmpty) return 0;
    return records.where(selector).length / records.length * 100;
  }

  double getCageHangRate() {
    if (records.isEmpty) return 0;
    return records.where((r) => r.cageHang != 'None').length / records.length * 100;
  }

  String getCoralPlacedStats() {
    if (records.isEmpty) return '0/0 - 0%';
    int successful = records.where((r) => r.coralPlaced != 'No').length;
    return '${successful}/${records.length} - ${(successful/records.length * 100).round()}%';
  }

  String getRankingPointStats() {
    if (records.isEmpty) return '0/0 - 0%';
    int successful = records.where((r) => r.rankingPoint).length;
    return '${successful}/${records.length} - ${(successful/records.length * 100).round()}%';
  }

  String formatAverage(num Function(ScoutingRecord) selector) {
    double avg = getAverage(selector);
    if (avg == 0) return '0.0';
    return '${avg.toStringAsFixed(1)}${records.length > 1 ? ' avg' : ''}';
  }

  String formatSuccessRate(bool Function(ScoutingRecord) selector) {
    if (records.isEmpty) return '0/0 - 0%';
    int successful = records.where(selector).length;
    return '${successful}/${records.length} - ${(successful/records.length * 100).round()}%';
  }

  String formatCageHangStats() {
    if (records.isEmpty) return '0/0 - 0%';
    int successful = records.where((r) => r.cageHang != 'None').length;
    return '${successful}/${records.length} - ${(successful/records.length * 100).round()}%';
  }

  String formatBreakdownRate() {
    if (records.isEmpty) return '0/0 - 0%';
    int breakdowns = records.where((r) => r.breakdown).length;
    return '${breakdowns}/${records.length} - ${(breakdowns/records.length * 100).round()}%';
  }
}

class ComparisonPage extends StatefulWidget {
  final List<ScoutingRecord> records;
  const ComparisonPage({Key? key, required this.records}) : super(key: key);

  @override
  _ComparisonPageState createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LinkedScrollControllerGroup _scrollControllers = LinkedScrollControllerGroup();
  late ScrollController _headerScrollController;
  late ScrollController _contentScrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _headerScrollController = _scrollControllers.addAndGetController();
    _contentScrollController = _scrollControllers.addAndGetController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose scroll controllers first
    _scrollControllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<int, List<ScoutingRecord>> recordsByTeam = {};
    for (var record in widget.records) {
      recordsByTeam.putIfAbsent(record.teamNumber, () => []).add(record);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Compare Teams'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Material(
            elevation: 4,
            child: Column(
              children: [
                // Team cards
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: SizedBox(
                    height: 100,  // Match the team card height
                    child: ListView.builder(
                      controller: _headerScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: recordsByTeam.length,
                      itemBuilder: (context, index) {
                        final entry = recordsByTeam.entries.elementAt(index);
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 20),
                          child: _buildTeamCard(
                            teamNumber: entry.key,
                            matches: entry.value,
                            isMultipleMatches: entry.value.length > 1,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Tab bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: const [
                    Tab(icon: Icon(Icons.auto_awesome), text: 'Auto'),
                    Tab(icon: Icon(Icons.sports_esports), text: 'Teleop'),
                    Tab(icon: Icon(Icons.flag), text: 'Endgame'),
                    Tab(icon: Icon(Icons.analytics), text: 'Overview'),
                  ],
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _contentScrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),  // Match team cards padding
                    child: AutoTab(records: _processRecords(recordsByTeam)),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _contentScrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: TeleopTab(records: _processRecords(recordsByTeam)),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _contentScrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: EndgameTab(records: _processRecords(recordsByTeam)),
                  ),
                ),
                OverviewTab(records: widget.records),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ScoutingRecord> _processRecords(Map<int, List<ScoutingRecord>> recordsByTeam) {
    return recordsByTeam.entries.map((entry) {
      if (entry.value.length == 1) return entry.value.first;
      
      // Calculate averages for multiple matches
      var matches = entry.value;
      return ScoutingRecord(
        timestamp: matches.first.timestamp,
        matchNumber: matches.first.matchNumber,
        matchType: '${matches.length} Matches (Avg)',
        teamNumber: entry.key,
        isRedAlliance: matches.first.isRedAlliance,
        
        // Auto
        autoTaxis: _mostCommon(matches.map((r) => r.autoTaxis)),
        autoCoralPreloaded: _mostCommon(matches.map((r) => r.autoCoralPreloaded)),
        autoAlgaeRemoved: _average(matches.map((r) => r.autoAlgaeRemoved)).round(),
        autoCoralHeight4Success: _average(matches.map((r) => r.autoCoralHeight4Success)).round(),
        autoCoralHeight4Failure: _average(matches.map((r) => r.autoCoralHeight4Failure)).round(),
        autoCoralHeight3Success: _average(matches.map((r) => r.autoCoralHeight3Success)).round(),
        autoCoralHeight3Failure: _average(matches.map((r) => r.autoCoralHeight3Failure)).round(),
        autoCoralHeight2Success: _average(matches.map((r) => r.autoCoralHeight2Success)).round(),
        autoCoralHeight2Failure: _average(matches.map((r) => r.autoCoralHeight2Failure)).round(),
        autoCoralHeight1Success: _average(matches.map((r) => r.autoCoralHeight1Success)).round(),
        autoCoralHeight1Failure: _average(matches.map((r) => r.autoCoralHeight1Failure)).round(),
        autoAlgaeInNet: _average(matches.map((r) => r.autoAlgaeInNet)).round(),
        autoAlgaeInProcessor: _average(matches.map((r) => r.autoAlgaeInProcessor)).round(),

        // Teleop
        teleopCoralHeight4Success: _average(matches.map((r) => r.teleopCoralHeight4Success)).round(),
        teleopCoralHeight4Failure: _average(matches.map((r) => r.teleopCoralHeight4Failure)).round(),
        teleopCoralHeight3Success: _average(matches.map((r) => r.teleopCoralHeight3Success)).round(),
        teleopCoralHeight3Failure: _average(matches.map((r) => r.teleopCoralHeight3Failure)).round(),
        teleopCoralHeight2Success: _average(matches.map((r) => r.teleopCoralHeight2Success)).round(),
        teleopCoralHeight2Failure: _average(matches.map((r) => r.teleopCoralHeight2Failure)).round(),
        teleopCoralHeight1Success: _average(matches.map((r) => r.teleopCoralHeight1Success)).round(),
        teleopCoralHeight1Failure: _average(matches.map((r) => r.teleopCoralHeight1Failure)).round(),
        teleopCoralRankingPoint: _mostCommon(matches.map((r) => r.teleopCoralRankingPoint)),
        teleopAlgaeRemoved: _average(matches.map((r) => r.teleopAlgaeRemoved)).round(),
        teleopAlgaeProcessorAttempts: _average(matches.map((r) => r.teleopAlgaeProcessorAttempts)).round(),
        teleopAlgaeProcessed: _average(matches.map((r) => r.teleopAlgaeProcessed)).round(),
        teleopAlgaeScoredInNet: _average(matches.map((r) => r.teleopAlgaeScoredInNet)).round(),
        teleopCanPickupAlgae: _mostCommon(matches.map((r) => r.teleopCanPickupAlgae)),
        teleopCoralPickupMethod: _mostCommonString(matches.map((r) => r.teleopCoralPickupMethod)),

        // Endgame
        endgameReturnedToBarge: _mostCommon(matches.map((r) => r.endgameReturnedToBarge)),
        endgameCageHang: _mostCommonString(matches.map((r) => r.endgameCageHang)),
        endgameBargeRankingPoint: _mostCommon(matches.map((r) => r.endgameBargeRankingPoint)),

        // Other
        otherCoOpPoint: _mostCommon(matches.map((r) => r.otherCoOpPoint)),
        otherBreakdown: _mostCommon(matches.map((r) => r.otherBreakdown)),
        otherComments: matches.map((r) => r.otherComments).where((c) => c.isNotEmpty).join('; '),

        // Legacy fields
        cageType: _mostCommonString(matches.map((r) => r.cageType)),
        coralPreloaded: _mostCommon(matches.map((r) => r.coralPreloaded)),
        taxis: _mostCommon(matches.map((r) => r.taxis)),
        algaeRemoved: _average(matches.map((r) => r.algaeRemoved)).round(),
        coralPlaced: _mostCommonString(matches.map((r) => r.coralPlaced)),
        rankingPoint: _mostCommon(matches.map((r) => r.rankingPoint)),
        canPickupCoral: _mostCommon(matches.map((r) => r.canPickupCoral)),
        canPickupAlgae: _mostCommon(matches.map((r) => r.canPickupAlgae)),
        algaeScoredInNet: _average(matches.map((r) => r.algaeScoredInNet)).round(),
        coralRankingPoint: _mostCommon(matches.map((r) => r.coralRankingPoint)),
        algaeProcessed: _average(matches.map((r) => r.algaeProcessed)).round(),
        processedAlgaeScored: _average(matches.map((r) => r.processedAlgaeScored)).round(),
        processorCycles: _average(matches.map((r) => r.processorCycles)).round(),
        coOpPoint: _mostCommon(matches.map((r) => r.coOpPoint)),
        returnedToBarge: _mostCommon(matches.map((r) => r.returnedToBarge)),
        cageHang: _mostCommonString(matches.map((r) => r.cageHang)),
        bargeRankingPoint: _mostCommon(matches.map((r) => r.bargeRankingPoint)),
        breakdown: _mostCommon(matches.map((r) => r.breakdown)),
        comments: matches.map((r) => r.comments).where((c) => c.isNotEmpty).join('; '),
        coralPickupMethod: _mostCommonString(matches.map((r) => r.coralPickupMethod)),
        feederStation: _mostCommonString(matches.map((r) => r.feederStation)),
        coralOnReefHeight1: _average(matches.map((r) => r.coralOnReefHeight1)).round(),
        coralOnReefHeight2: _average(matches.map((r) => r.coralOnReefHeight2)).round(),
        coralOnReefHeight3: _average(matches.map((r) => r.coralOnReefHeight3)).round(),
        coralOnReefHeight4: _average(matches.map((r) => r.coralOnReefHeight4)).round(),
        robotPath: matches.first.robotPath, // Take the first match's path
      );
    }).toList();
  }

  int _average(Iterable<int> values) {
    if (values.isEmpty) return 0;
    return (values.reduce((a, b) => a + b) / values.length).round();
  }

  bool _mostCommon(Iterable<bool> values) {
    if (values.isEmpty) return false;
    return values.where((v) => v).length > values.length / 2;
  }

  String _mostCommonString(Iterable<String> values) {
    if (values.isEmpty) return '';
    Map<String, int> counts = {};
    for (var value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    return counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  Widget _buildTeamCard({
    required int teamNumber,
    required List<ScoutingRecord> matches,
    required bool isMultipleMatches,
  }) {
    final record = matches.first;
    return SizedBox(
      width: 140,
      height: 100,  // Fixed height to prevent overflow
      child: Card(
        margin: EdgeInsets.zero,  // Remove default card margin
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),  // Reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,  // Center content vertically
            children: [
              Text(
                'Team $teamNumber',
                style: TextStyle(
                  fontSize: 18,  // Slightly reduced font size
                  fontWeight: FontWeight.bold,
                  color: record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),  // Reduced spacing
              Text(
                isMultipleMatches
                    ? '${matches.length} Matches'
                    : 'Match ${record.matchNumber}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),  // Reduced spacing
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),  // Reduced padding
                decoration: BoxDecoration(
                  color: (record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.isRedAlliance ? 'Red' : 'Blue',
                  style: TextStyle(
                    color: record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableTab(Widget content, int teamCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _contentScrollController,
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: content,
      ),
    );
  }
}

class AutoTab extends StatelessWidget {
  final List<ScoutingRecord> records;

  const AutoTab({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),  // Remove left padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Starting Configuration
          SectionHeader(
            title: 'Starting Configuration',
            color: Theme.of(context).colorScheme.primary,
          ),
          ComparisonMetric(
            label: 'Cage Type',
            values: records.map((r) => r.cageType).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Coral Preloaded',
            values: records.map((r) => r.coralPreloaded ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),

          // Auto Movement
          SectionHeader(
            title: 'Auto Movement',
            color: Theme.of(context).colorScheme.primary,
          ),
          ComparisonMetric(
            label: 'Taxis',
            values: records.map((r) => r.taxis ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),

          // Auto Scoring
          SectionHeader(
            title: 'Auto Scoring',
            color: Theme.of(context).colorScheme.primary,
          ),
          ComparisonMetric(
            label: 'Algae Removed',
            values: records.map((r) => r.algaeRemoved.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Algae in Net',
            values: records.map((r) => r.autoAlgaeInNet.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Algae in Processor',
            values: records.map((r) => r.autoAlgaeInProcessor.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Coral Placed',
            values: records.map((r) => r.coralPlaced).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Ranking Point',
            values: records.map((r) => r.rankingPoint ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
        ],
      ),
    );
  }
}

class ComparisonMetric extends StatelessWidget {
  final String label;
  final List<String> values;
  final List<Color> colors;  // This will only be used for team alliance colors

  const ComparisonMetric({
    Key? key,
    required this.label,
    required this.values,
    required this.colors,
  }) : super(key: key);

  Color _getValueColor(String value) {
    // For Yes/No values
    if (value == 'Yes') return Colors.green.withOpacity(0.15);
    if (value == 'No') return Colors.red.withOpacity(0.15);
    if (value.startsWith('Yes')) return Colors.green.withOpacity(0.15);
    
    // For numeric values
    if (value == '0' || value == '0.0') return Colors.red.withOpacity(0.15);
    if (double.tryParse(value) != null) {
      double numValue = double.parse(value);
      if (numValue > 0) return Colors.green.withOpacity(0.15);
      if (numValue < 0) return Colors.red.withOpacity(0.15);
    }
    
    // For cage hang values
    if (value == 'None') return Colors.red.withOpacity(0.15);
    if (value == 'Shallow') return Colors.blue.shade200.withOpacity(0.3);
    if (value == 'Deep') return Colors.blue.shade700.withOpacity(0.3);
    
    return Colors.transparent;
  }

  Color _getBorderColor(String value) {
    // For Yes/No values
    if (value == 'Yes') return Colors.green.shade700;
    if (value == 'No') return Colors.red.shade700;
    if (value.startsWith('Yes')) return Colors.green.shade700;
    
    // For numeric values
    if (value == '0' || value == '0.0') return Colors.red.shade700;
    if (double.tryParse(value) != null) {
      double numValue = double.parse(value);
      if (numValue > 0) return Colors.green.shade700;
      if (numValue < 0) return Colors.red.shade700;
    }
    
    // For cage hang values
    if (value == 'None') return Colors.red.shade700;
    if (value == 'Shallow') return Colors.blue.shade400;
    if (value == 'Deep') return Colors.blue.shade900;
    
    return Colors.grey;
  }

  Color _getTextColor(BuildContext context, String value) {
    return _getBorderColor(value);  // Use the same color as border for text
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,  // Decreased from 16
              fontWeight: FontWeight.w400,  // Made lighter
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),  // Slightly dimmed
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            for (int i = 0; i < values.length; i++)
              Container(
                width: 140,  // Fixed width for all boxes
                height: 50,  // Fixed height for all boxes
                margin: const EdgeInsets.only(right: 20, bottom: 16),
                decoration: BoxDecoration(
                  color: _getValueColor(values[i]),
                  border: Border.all(
                    color: _getBorderColor(values[i]),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(  // Center the text both horizontally and vertically
                  child: Text(
                    values[i],
                    style: TextStyle(
                      color: _getTextColor(context, values[i]),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class TeleopTab extends StatelessWidget {
  final List<ScoutingRecord> records;

  const TeleopTab({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),  // Remove left padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coral Scoring Section
          SectionHeader(
            title: 'Coral Scoring',
            color: Theme.of(context).colorScheme.primary,
          ),
          ComparisonMetric(
            label: 'Height 1 Coral',
            values: records.map((r) => r.coralOnReefHeight1.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Height 2 Coral',
            values: records.map((r) => r.coralOnReefHeight2.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Height 3 Coral',
            values: records.map((r) => r.coralOnReefHeight3.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Height 4 Coral',
            values: records.map((r) => r.coralOnReefHeight4.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Coral Ranking Point',
            values: records.map((r) => r.coralRankingPoint ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),

          // Algae Processing Section
          SectionHeader(
            title: 'Algae Processing',
            color: Theme.of(context).colorScheme.primary,
          ),
          ComparisonMetric(
            label: 'Algae Scored in Net',
            values: records.map((r) => r.algaeScoredInNet.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Algae Processed',
            values: records.map((r) => r.algaeProcessed.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Processed Algae Scored',
            values: records.map((r) => r.processedAlgaeScored.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Processor Cycles',
            values: records.map((r) => r.processorCycles.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),

          // Co-op Section
          SectionHeader(
            title: 'Co-op',
            color: Theme.of(context).colorScheme.primary,
          ),
          ComparisonMetric(
            label: 'Co-op Point',
            values: records.map((r) => r.coOpPoint ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
        ],
      ),
    );
  }
}

class EndgameTab extends StatelessWidget {
  final List<ScoutingRecord> records;

  const EndgameTab({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),  // Remove left padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Endgame',
            color: Theme.of(context).colorScheme.primary,
          ),
          ComparisonMetric(
            label: 'Returned to Barge',
            values: records.map((r) => r.returnedToBarge ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Cage Hang',
            values: records.map((r) => r.cageHang).toList(),  // This should now show 'None', 'Shallow', or 'Deep'
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Barge RP',
            values: records.map((r) => r.bargeRankingPoint ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
        ],
      ),
    );
  }
}

class OverviewTab extends StatelessWidget {
  final List<ScoutingRecord> records;

  const OverviewTab({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...records.map((record) => TeamOverviewCard(record: record)).toList(),
        ],
      ),
    );
  }
}

class TeamOverviewCard extends StatelessWidget {
  final ScoutingRecord record;

  const TeamOverviewCard({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (record.isRedAlliance ? Colors.red : Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Team ${record.teamNumber} - Match ${record.matchNumber}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: record.isRedAlliance ? Colors.red : Colors.blue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(record.comments.isEmpty ? 'No comments' : record.comments),
                SizedBox(height: 16),
                if (record.robotPath != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => drawing.DrawingPage(
                            isRedAlliance: record.isRedAlliance,
                            initialDrawing: record.robotPath,
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.map),
                    label: Text('View Auto Path'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const SectionHeader({
    Key? key,
    required this.title,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),  // Increased padding
      child: Text(
        title.toUpperCase(),  // Make it uppercase for emphasis
        style: TextStyle(
          fontSize: 20,  // Increased from 16
          fontWeight: FontWeight.bold,  // Made bolder
          color: color,
          letterSpacing: 1.2,  // Added letter spacing
        ),
      ),
    );
  }
}