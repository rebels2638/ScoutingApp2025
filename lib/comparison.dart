import 'package:flutter/material.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'database_helper.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

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

class _ComparisonViewState extends State<ComparisonView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _horizontalScrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalScrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width,
            ),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.records.map((record) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TeamHeader(
                    teamNumber: record.teamNumber,
                    isRedAlliance: record.isRedAlliance,
                    matchCount: widget.records.where((r) => r.teamNumber == record.teamNumber).length,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,  // Make tabs scrollable
          tabs: const [
            Tab(text: 'Auto'),
            Tab(text: 'Teleop'),
            Tab(text: 'Endgame'),
            Tab(text: 'Overview'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: AutoComparisonTab(records: widget.records),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: TeleopComparisonTab(records: widget.records),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: EndgameComparisonTab(records: widget.records),
              ),
              OverviewComparisonTab(records: widget.records),
            ],
          ),
        ),
      ],
    );
  }
}

class TeamHeader extends StatelessWidget {
  final int teamNumber;
  final bool isRedAlliance;
  final int matchCount;

  const TeamHeader({
    Key? key,
    required this.teamNumber,
    required this.isRedAlliance,
    required this.matchCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isRedAlliance ? Colors.red : Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isRedAlliance ? Colors.red : Colors.blue).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Team $teamNumber',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isRedAlliance ? Colors.red : Colors.blue,
              ),
            ),
          ),
          Text(
            '$matchCount matches',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
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
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,  // Fixed width for labels
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...List.generate(values.length, (index) {
            return Container(
              width: 100,  // Fixed width for values
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: colors[index].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors[index].withOpacity(0.3),
                ),
              ),
              child: Text(
                values[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors[index],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AutoComparisonTab extends StatelessWidget {
  final List<ScoutingRecord> records;

  const AutoComparisonTab({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ComparisonMetric(
            label: 'Algae Removed',
            values: records.map((r) => r.algaeRemoved.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Algae in Net',
            values: records.map((r) => r.autoAlgaeInNet.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Algae in Processor',
            values: records.map((r) => r.autoAlgaeInProcessor.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Taxis',
            values: records.map((r) => r.taxis ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Coral Placed',
            values: records.map((r) => r.coralPlaced).toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Ranking Point',
            values: records.map((r) => r.rankingPoint ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
        ],
      ),
    );
  }
}

class TeleopComparisonTab extends StatelessWidget {
  final List<ScoutingRecord> records;

  const TeleopComparisonTab({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ComparisonMetric(
            label: 'Algae in Net',
            values: records.map((r) => r.algaeScoredInNet.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Algae Processed',
            values: records.map((r) => r.algaeProcessed.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Processed Scored',
            values: records.map((r) => r.processedAlgaeScored.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Processor Cycles',
            values: records.map((r) => r.processorCycles.toString()).toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Co-Op Point',
            values: records.map((r) => r.coOpPoint ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
        ],
      ),
    );
  }
}

class EndgameComparisonTab extends StatelessWidget {
  final List<ScoutingRecord> records;

  const EndgameComparisonTab({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ComparisonMetric(
            label: 'Returned to Barge',
            values: records.map((r) => r.returnedToBarge ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Cage Hang',
            values: records.map((r) => r.cageHang).toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
          ComparisonMetric(
            label: 'Barge RP',
            values: records.map((r) => r.bargeRankingPoint ? 'Yes' : 'No').toList(),
            colors: records.map((r) => r.isRedAlliance ? Colors.red : Colors.blue).toList(),
          ),
        ],
      ),
    );
  }
}

class OverviewComparisonTab extends StatelessWidget {
  final List<ScoutingRecord> records;

  const OverviewComparisonTab({Key? key, required this.records}) : super(key: key);

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
                          builder: (context) => DrawingPage(
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