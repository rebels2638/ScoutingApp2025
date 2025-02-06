import 'package:flutter/material.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'drawing_page.dart';

class ComparisonPage extends StatefulWidget {
  final List<ScoutingRecord> records;

  const ComparisonPage({Key? key, required this.records}) : super(key: key);

  @override
  _ComparisonPageState createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  late ScrollController _horizontalController;
  late ScrollController _verticalController;
  List<ScoutingRecord> records = [];

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
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
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: highlight 
            ? Colors.blue.shade50 
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900  // Dark background for data cells in dark mode
                : null,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700  // Darker border for dark mode
              : Colors.grey.shade300,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white  // White text for dark mode
              : Colors.black,
        ),
      ),
    );
  }

  List<DataRow> _buildRows() {
    List<DataRow> rows = [];

    // match info
    rows.addAll([
      DataRow(cells: [
        DataCell(_buildHeaderCell('Match')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.matchNumber}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Team')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.teamNumber}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Type')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.matchType))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Alliance')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.isRedAlliance ? 'Red' : 'Blue'))),
      ]),
    ]);

    // auto section
    rows.add(DataRow(cells: [
      DataCell(_buildHeaderCell('Autonomous')),
      ...widget.records.map((r) => DataCell(_buildDataCell(''))),
    ]));
    
    rows.addAll([
      DataRow(cells: [
        DataCell(_buildHeaderCell('Cage Type')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.cageType))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral Preloaded')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.coralPreloaded ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Taxis')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.taxis ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Algae Removed')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.algaeRemoved}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral Placed')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.coralPlaced))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral Pickup Method')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.coralPickupMethod))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Auto RP')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.rankingPoint ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Can Pickup')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.canPickupAlgae ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Auto Algae in Net')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.autoAlgaeInNet}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Auto Algae in Processor')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.autoAlgaeInProcessor}'))),
      ]),
    ]);

    // teleop section
    rows.add(DataRow(cells: [
      DataCell(_buildHeaderCell('Teleop')),
      ...widget.records.map((r) => DataCell(_buildDataCell(''))),
    ]));

    rows.addAll([
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral Height 1')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.coralOnReefHeight1}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral Height 2')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.coralOnReefHeight2}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral Height 3')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.coralOnReefHeight3}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral Height 4')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.coralOnReefHeight4}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Feeder Station')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.feederStation))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Net Algae')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.algaeScoredInNet}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral RP')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.coralRankingPoint ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Algae Processed')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.algaeProcessed}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Processed Scored')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.processedAlgaeScored}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Processor Cycles')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.processorCycles}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Co-Op Point')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.coOpPoint ? 'Yes' : 'No'))),
      ]),
    ]);

    // endgame section
    rows.add(DataRow(cells: [
      DataCell(_buildHeaderCell('Endgame')),
      ...widget.records.map((r) => DataCell(_buildDataCell(''))),
    ]));

    rows.addAll([
      DataRow(cells: [
        DataCell(_buildHeaderCell('Returned to Barge')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.returnedToBarge ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Cage Hang')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.cageHang))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Barge RP')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.bargeRankingPoint ? 'Yes' : 'No'))),
      ]),
    ]);

    // other section
    rows.add(DataRow(cells: [
      DataCell(_buildHeaderCell('Other')),
      ...widget.records.map((r) => DataCell(_buildDataCell(''))),
    ]));

    rows.addAll([
      DataRow(cells: [
        DataCell(_buildHeaderCell('Breakdown')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.breakdown ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Comments')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.comments))),
      ]),
    ]);

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Reset All Data'),
                    content: const Text(
                      'Are you sure you want to delete all saved scouting data? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete All'),
                        onPressed: () async {
                          await DatabaseHelper.instance.deleteAllRecords();
                          await _loadRecords(); // Reload the empty records
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All data has been deleted'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalController,
            child: SingleChildScrollView(
              controller: _verticalController,
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 0,
                columns: [
                  DataColumn(label: Container(width: 150)),
                  ...widget.records.map((r) => DataColumn(label: Container(width: 120))),
                ],
                rows: _buildRows(),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  flex: 1,
                  child: TelemetryOverlay(
                    telemetryData: widget.records.map((record) {
                      return '[Match ${record.matchNumber} - Team ${record.teamNumber}]\n${record.telemetry ?? "No telemetry data"}';
                    }).toList(),
                    onClose: () {
                      // Handle close if needed
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}