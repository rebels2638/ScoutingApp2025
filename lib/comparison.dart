import 'package:flutter/material.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'database_helper.dart';
import 'widgets/telemetry_overlay.dart';

class ComparisonPage extends StatefulWidget {
  final List<ScoutingRecord> records;

  const ComparisonPage({Key? key, required this.records}) : super(key: key);

  @override
  _ComparisonPageState createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> with SingleTickerProviderStateMixin {
  late ScrollController _horizontalController;
  late ScrollController _verticalController;
  late TabController _tabController;
  List<ScoutingRecord> records = [];

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
    _tabController = TabController(length: 4, vsync: this);
    records = widget.records;
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool highlight = false}) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: highlight 
            ? Colors.blue.shade50 
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : null,
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Comparison'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Auto'),
            Tab(text: 'Teleop'),
            Tab(text: 'Endgame'),
            Tab(text: 'Overview'),
          ],
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalController,
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AutoComparisonTab(records: widget.records),
                TeleopComparisonTab(records: widget.records),
                EndgameComparisonTab(records: widget.records),
                OverviewComparisonTab(records: widget.records),
              ],
            ),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          ...List.generate(
            values.length,
            (index) => Expanded(
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: colors[index].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  values[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors[index]),
                ),
              ),
            ),
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Autonomous Performance', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            ...records.map((record) => _buildAutoMetrics(context, record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoMetrics(BuildContext context, ScoutingRecord record) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team ${record.teamNumber}', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            ComparisonMetric(
              label: 'Taxis',
              values: [record.taxis ? 'Yes' : 'No'],
              colors: [record.isRedAlliance ? Colors.red : Colors.blue],
            ),
            ComparisonMetric(
              label: 'Auto Algae',
              values: ['${record.autoAlgaeInNet}'],
              colors: [record.isRedAlliance ? Colors.red : Colors.blue],
            ),
            // Add more auto metrics as needed
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Teleop Performance', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            ...records.map((record) => _buildTeleopMetrics(context, record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeleopMetrics(BuildContext context, ScoutingRecord record) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team ${record.teamNumber}', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            ComparisonMetric(
              label: 'Algae in Net',
              values: ['${record.algaeScoredInNet}'],
              colors: [record.isRedAlliance ? Colors.red : Colors.blue],
            ),
            // Add more teleop metrics
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Endgame Performance', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            ...records.map((record) => _buildEndgameMetrics(context, record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEndgameMetrics(BuildContext context, ScoutingRecord record) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team ${record.teamNumber}', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            ComparisonMetric(
              label: 'Cage Hang',
              values: [record.cageHang],
              colors: [record.isRedAlliance ? Colors.red : Colors.blue],
            ),
            // Add more endgame metrics
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Performance', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            ...records.map((record) => _buildOverviewMetrics(context, record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewMetrics(BuildContext context, ScoutingRecord record) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team ${record.teamNumber}', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            ComparisonMetric(
              label: 'Total Algae',
              values: ['${record.algaeScoredInNet + record.processedAlgaeScored}'],
              colors: [record.isRedAlliance ? Colors.red : Colors.blue],
            ),
            // Add more overview metrics
          ],
        ),
      ),
    );
  }
}