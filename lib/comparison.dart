import 'package:flutter/material.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'database_helper.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'drawing_page.dart';
import 'widgets/telemetry_overlay.dart';

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
  late List<TeamStats> teamStats;
  // Use a linked scroll controller group for horizontal synchronization.
  final LinkedScrollControllerGroup _linkedScrollControllerGroup = LinkedScrollControllerGroup();
  late ScrollController _headerScrollController;
  // We'll store each tab's horizontal controller here once created.
  final Map<int, ScrollController> _tabScrollControllers = {};
  late ScrollController _horizontalController;
  late ScrollController _verticalController;
  List<ScoutingRecord> records = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _headerScrollController = _linkedScrollControllerGroup.addAndGetController();
    _processTeamStats();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final loadedRecords = await DatabaseHelper.instance.getAllRecords();
    setState(() {
      records = loadedRecords;
    });
  }

  void _processTeamStats() {
    // Group records by team number
    final Map<int, List<ScoutingRecord>> teamRecords = {};
    for (var record in widget.records) {
      teamRecords.putIfAbsent(record.teamNumber, () => []).add(record);
    }

    // Create TeamStats objects and sort them so red alliance is on the right
    teamStats = teamRecords.entries.map((entry) {
      return TeamStats(
        teamNumber: entry.key,
        isRedAlliance: entry.value.first.isRedAlliance,
        records: entry.value,
      );
    }).toList();

    // Sort so that blue alliance is on the left and red alliance is on the right
    teamStats.sort((a, b) => a.isRedAlliance ? 1 : -1);
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _tabScrollControllers.forEach((_, controller) => controller.dispose());
    _tabController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('Team Comparison'),
        elevation: 0,
      ),
      // Use LayoutBuilder to enforce a definite width.
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Ensure content has at least 600 width.
          double contentWidth = constraints.maxWidth < 600 ? 600 : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Team stats header with synchronized horizontal scrolling
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _headerScrollController,
                      child: Row(
                        children: teamStats.map((stats) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 6),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: stats.isRedAlliance
                                  ? AppColors.redAlliance.withOpacity(0.1)
                                  : AppColors.blueAlliance.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: stats.isRedAlliance
                                    ? AppColors.redAlliance.withOpacity(0.3)
                                    : AppColors.blueAlliance.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${stats.teamNumber}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: stats.isRedAlliance
                                        ? AppColors.redAlliance
                                        : AppColors.blueAlliance,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${stats.records.length} matches${stats.records.length > 1 ? ' (avg)' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(icon: Icon(Icons.auto_awesome), text: 'Auto'),
                        Tab(icon: Icon(Icons.sports_esports), text: 'Teleop'),
                        Tab(icon: Icon(Icons.flag), text: 'Endgame'),
                        Tab(icon: Icon(Icons.analytics), text: 'Overview'),
                      ],
                    ),
                  ),
                  // Metrics area: fixed height with vertical scrolling.
                  Container(
                    height: 400, // Adjust height as needed.
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAutoTab(),
                        _buildTeleopTab(),
                        _buildEndgameTab(),
                        _buildOverviewTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String label, List<String> values, {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
            SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          // Insert a margin after the label for separation
          SizedBox(width: 16),
          ...teamStats.map((stats) {
            String value = values[teamStats.indexOf(stats)];
            return Container(
              margin: EdgeInsets.only(right: 16),
              alignment: Alignment.center,
              child: _buildMetricValue(value, stats.isRedAlliance),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMetricValue(String value, bool isRed) {
    // Always use the alliance color instead of checking the value.
    Color baseColor = isRed ? AppColors.redAlliance : AppColors.blueAlliance;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1), // Always apply a colored background.
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: baseColor.withOpacity(0.3), // Always include the border in the alliance color.
          width: 1,
        ),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: baseColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAutoTab() {
    int tabIndex = 0;
    _tabScrollControllers.putIfAbsent(tabIndex, () => _linkedScrollControllerGroup.addAndGetController());
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _tabScrollControllers[tabIndex],
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 600, minHeight: 400),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricRow(
                'Algae Removed',
                teamStats.map((stats) => stats.formatAverage((r) => r.algaeRemoved)).toList(),
                icon: Icons.grass,
              ),
              _buildMetricRow(
                'Algae In Net',
                teamStats.map((stats) => stats.formatAverage((r) => r.autoAlgaeInNet)).toList(),
                icon: Icons.sports_hockey,
              ),
              _buildMetricRow(
                'Taxis',
                teamStats.map((stats) => stats.formatSuccessRate((r) => r.taxis)).toList(),
                icon: Icons.directions_car,
              ),
              _buildMetricRow(
                'Algae In Processor',
                teamStats.map((stats) => stats.formatAverage((r) => r.autoAlgaeInProcessor)).toList(),
                icon: Icons.build,
              ),
              _buildMetricRow(
                'Coral Placed',
                teamStats.map((stats) => stats.getCoralPlacedStats()).toList(),
                icon: Icons.sports_score,
              ),
              _buildMetricRow(
                'Ranking Point',
                teamStats.map((stats) => stats.getRankingPointStats()).toList(),
                icon: Icons.star,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeleopTab() {
    int tabIndex = 1;
    _tabScrollControllers.putIfAbsent(tabIndex, () => _linkedScrollControllerGroup.addAndGetController());
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _tabScrollControllers[tabIndex],
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 600),
        child: ListView(
          padding: EdgeInsets.all(16),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildMetricRow(
              'Algae In Net',
              teamStats.map((stats) => stats.formatAverage((r) => r.algaeScoredInNet)).toList(),
              icon: Icons.sports_hockey,
            ),
            _buildMetricRow(
              'Coral Ranking Point',
              teamStats.map((stats) => stats.formatSuccessRate((r) => r.coralRankingPoint)).toList(),
              icon: Icons.star,
            ),
            _buildMetricRow(
              'Algae Processed',
              teamStats.map((stats) => stats.formatAverage((r) => r.algaeProcessed)).toList(),
              icon: Icons.build,
            ),
            _buildMetricRow(
              'Processed Algae Scored',
              teamStats.map((stats) => stats.formatAverage((r) => r.processedAlgaeScored)).toList(),
              icon: Icons.build,
            ),
            _buildMetricRow(
              'Processor Cycles',
              teamStats.map((stats) => stats.formatAverage((r) => r.processorCycles)).toList(),
              icon: Icons.build,
            ),
            _buildMetricRow(
              'Co-Op Point',
              teamStats.map((stats) => stats.formatSuccessRate((r) => r.coOpPoint)).toList(),
              icon: Icons.group,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndgameTab() {
    int tabIndex = 2;
    _tabScrollControllers.putIfAbsent(tabIndex, () => _linkedScrollControllerGroup.addAndGetController());
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _tabScrollControllers[tabIndex],
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 600),
        child: ListView(
          padding: EdgeInsets.all(16),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildMetricRow(
              'Returned to Barge',
              teamStats.map((stats) => stats.formatSuccessRate((r) => r.returnedToBarge)).toList(),
              icon: Icons.directions_boat,
            ),
            _buildMetricRow(
              'Cage Hang',
              teamStats.map((stats) => stats.formatCageHangStats()).toList(),
              icon: Icons.flag,
            ),
            _buildMetricRow(
              'Barge Ranking Point',
              teamStats.map((stats) => stats.formatSuccessRate((r) => r.bargeRankingPoint)).toList(),
              icon: Icons.star,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    int tabIndex = 3;
    _tabScrollControllers.putIfAbsent(tabIndex, () => _linkedScrollControllerGroup.addAndGetController());
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _tabScrollControllers[tabIndex],
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 600),
        child: ListView(
          padding: EdgeInsets.all(16),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildMetricRow(
              'Matches',
              teamStats.map((stats) => stats.records.length.toString()).toList(),
              icon: Icons.format_list_numbered,
            ),
            _buildMetricRow(
              'Match Type',
              teamStats.map((stats) => stats.records.first.matchType).toList(),
              icon: Icons.category,
            ),
            _buildMetricRow(
              'Breakdown Rate',
              teamStats.map((stats) => stats.formatBreakdownRate()).toList(),
              icon: Icons.build_circle,
            ),
          ],
        ),
      ),
    );
  }
}