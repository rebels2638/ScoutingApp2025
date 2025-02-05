import 'package:flutter/material.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'drawing_page.dart';

class ComparisonPage extends StatelessWidget {
  final List<ScoutingRecord> records;

  const ComparisonPage({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Comparison'),
        centerTitle: true,
      ),
      body: ComparisonView(records: records),
    );
  }
}

class ComparisonView extends StatefulWidget {
  final List<ScoutingRecord> records;

  const ComparisonView({Key? key, required this.records}) : super(key: key);

  @override
  State<ComparisonView> createState() => _ComparisonViewState();
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
        // Team Headers with Animation
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: AppShadows.small,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalScrollController,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: widget.records.map((record) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
        ),

        // Tab Bar with Animation
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            physics: const BouncingScrollPhysics(),
            tabs: [
              _buildTab(Icons.auto_awesome, 'Auto'),
              _buildTab(Icons.sports_esports, 'Teleop'),
              _buildTab(Icons.flag, 'Endgame'),
              _buildTab(Icons.summarize, 'Overview'),
            ],
          ),
        ),

        // Tab Content with Animation
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildTabContent(AutoComparisonTab(records: widget.records)),
              _buildTabContent(TeleopComparisonTab(records: widget.records)),
              _buildTabContent(EndgameComparisonTab(records: widget.records)),
              _buildTabContent(OverviewComparisonTab(records: widget.records)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildTabContent(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: child,
      ),
    );
  }
}

// Updated TeamHeader with animations
class TeamHeader extends StatefulWidget {
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
  State<TeamHeader> createState() => _TeamHeaderState();
}

class _TeamHeaderState extends State<TeamHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (widget.isRedAlliance ? Colors.red : Colors.blue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.isRedAlliance ? Colors.red : Colors.blue).withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.isRedAlliance ? Colors.red : Colors.blue).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Team ${widget.teamNumber}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.isRedAlliance ? Colors.red : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (widget.isRedAlliance ? Colors.red : Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.matchCount} matches',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isRedAlliance ? Colors.red : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
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