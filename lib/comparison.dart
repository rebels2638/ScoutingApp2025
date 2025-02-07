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
  
  ScrollController addAndGetController() {
    final controller = ScrollController();
    _controllers.add(controller);
    controller.addListener(() {
      if (_isJumping) return;
      _isJumping = true;
      for (final other in _controllers) {
        // Do not update the same controller or controllers without clients.
        if (other == controller || !other.hasClients) continue;
        // If the difference is significant update.
        if ((other.offset - controller.offset).abs() > 1.0) {
          other.jumpTo(controller.offset);
        }
      }
      _isJumping = false;
    });
    return controller;
  }
  
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
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
    _headerScrollController.dispose();
    _contentScrollController.dispose();
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
                Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListView.builder(
                    controller: _headerScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: recordsByTeam.length,
                    itemBuilder: (context, index) {
                      final entry = recordsByTeam.entries.elementAt(index);
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildTeamCard(
                          teamNumber: entry.key,
                          matches: entry.value,
                          isMultipleMatches: entry.value.length > 1,
                        ),
                      );
                    },
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
                _buildScrollableTab(AutoTab(records: _processRecords(recordsByTeam)), recordsByTeam.length),
                _buildScrollableTab(TeleopTab(records: _processRecords(recordsByTeam)), recordsByTeam.length),
                _buildScrollableTab(EndgameTab(records: _processRecords(recordsByTeam)), recordsByTeam.length),
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
        teamNumber: entry.key,
        matchNumber: matches.first.matchNumber,
        matchType: '${matches.length} Matches (Avg)',
        isRedAlliance: matches.first.isRedAlliance,
        timestamp: matches.first.timestamp,
        // Required fields
        cageType: matches.first.cageType,
        coralPreloaded: _mostCommon(matches.map((r) => r.coralPreloaded)),
        taxis: _mostCommon(matches.map((r) => r.taxis)),
        algaeRemoved: _average(matches.map((r) => r.algaeRemoved)),
        coralPlaced: _mostCommonString(matches.map((r) => r.coralPlaced)),
        rankingPoint: _mostCommon(matches.map((r) => r.rankingPoint)),
        canPickupCoral: _mostCommon(matches.map((r) => r.canPickupCoral)),
        canPickupAlgae: _mostCommon(matches.map((r) => r.canPickupAlgae)),
        coralPickupMethod: _mostCommonString(matches.map((r) => r.coralPickupMethod)),
        // Auto
        autoAlgaeInNet: _average(matches.map((r) => r.autoAlgaeInNet)),
        autoAlgaeInProcessor: _average(matches.map((r) => r.autoAlgaeInProcessor)),
        // Teleop
        algaeScoredInNet: _average(matches.map((r) => r.algaeScoredInNet)),
        coralRankingPoint: _mostCommon(matches.map((r) => r.coralRankingPoint)),
        algaeProcessed: _average(matches.map((r) => r.algaeProcessed)),
        processedAlgaeScored: _average(matches.map((r) => r.processedAlgaeScored)),
        processorCycles: _average(matches.map((r) => r.processorCycles)),
        coOpPoint: _mostCommon(matches.map((r) => r.coOpPoint)),
        // Endgame
        returnedToBarge: _mostCommon(matches.map((r) => r.returnedToBarge)),
        cageHang: _mostCommonString(matches.map((r) => r.cageHang)),
        bargeRankingPoint: _mostCommon(matches.map((r) => r.bargeRankingPoint)),
        // Other
        breakdown: _mostCommon(matches.map((r) => r.breakdown)),
        comments: matches.map((r) => r.comments).where((c) => c.isNotEmpty).join('; '),
        // Coral placement
        coralOnReefHeight1: _average(matches.map((r) => r.coralOnReefHeight1)),
        coralOnReefHeight2: _average(matches.map((r) => r.coralOnReefHeight2)),
        coralOnReefHeight3: _average(matches.map((r) => r.coralOnReefHeight3)),
        coralOnReefHeight4: _average(matches.map((r) => r.coralOnReefHeight4)),
        // Additional fields
        feederStation: _mostCommonString(matches.map((r) => r.feederStation)),
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
      width: 150,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Team $teamNumber',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                isMultipleMatches
                    ? '${matches.length} Matches (Avg)'
                    : 'Match ${record.matchNumber}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  record.isRedAlliance ? 'Red' : 'Blue',
                  style: TextStyle(
                    color: record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
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
            label: 'Taxis',
            values: records.map((r) => r.taxis ? 'Yes' : 'No').toList(),
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
  final List<Color> colors;

  const ComparisonMetric({
    Key? key,
    required this.label,
    required this.values,
    required this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: values.asMap().entries.map((entry) {
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: values[entry.key].isEmpty 
                        ? Colors.black12 
                        : colors[entry.key].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: values[entry.key].isEmpty 
                        ? null 
                        : Border.all(
                            color: colors[entry.key].withOpacity(0.3),
                          ),
                    image: values[entry.key].isEmpty 
                        ? const DecorationImage(
                            image: AssetImage('assets/hazard_stripes.png'),
                            repeat: ImageRepeat.repeat,
                            opacity: 0.2,
                          )
                        : null,
                  ),
                  child: values[entry.key].isEmpty 
                      ? null
                      : Text(
                          values[entry.key],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors[entry.key],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class TeleopTab extends StatelessWidget {
  final List<ScoutingRecord> records;

  const TeleopTab({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Teleop',
            color: Theme.of(context).colorScheme.primary,
          ),
          ComparisonMetric(
            label: 'Algae in Net',
            values: records.map((r) => r.algaeScoredInNet.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Algae Processed',
            values: records.map((r) => r.algaeProcessed.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Processed Scored',
            values: records.map((r) => r.processedAlgaeScored.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Processor Cycles',
            values: records.map((r) => r.processorCycles.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance).toList(),
          ),
          ComparisonMetric(
            label: 'Co-Op Point',
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
      padding: const EdgeInsets.all(16),
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
            values: records.map((r) => r.cageHang).toList(),
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
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}