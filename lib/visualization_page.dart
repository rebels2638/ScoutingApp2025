import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'dart:math' show max, min, pow, sqrt;
import 'package:flutter/services.dart';
import 'database_helper.dart';

class VisualizationPage extends StatefulWidget {
  final List<ScoutingRecord> records;

  const VisualizationPage({Key? key, required this.records}) : super(key: key);

  @override
  _VisualizationPageState createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage> {
  int? selectedTeam;
  List<int> teamNumbers = [];
  int _selectedIndex = 0;
  String _coralView = 'Total'; // 'total', 'teleop', or 'auto'
  String _algaeView = 'Total'; // 'total', 'teleop', or 'auto'
  
  final List<ChartType> _chartTypes = [
    ChartType(
      title: 'Coral Placement',
      icon: Icons.height,
      description: 'Average pieces at each height',
    ),
    ChartType(
      title: 'Coral OT',
      icon: Icons.timeline,
      description: 'Coral scoring over time',
    ),
    ChartType(
      title: 'Algae OT',
      icon: Icons.circle,
      description: 'Algae scoring over time',
    ),
    ChartType(
      title: 'Endgame',
      icon: Icons.flag,
      description: 'Cage hang and barge return rates',
    ),
    ChartType(
      title: 'Ranking Points',
      icon: Icons.star,
      description: 'Success rates by type',
    ),
    ChartType(
      title: 'Auto vs Teleop',
      icon: Icons.compare_arrows,
      description: 'Scoring comparison by phase',
    ),
    ChartType(
      title: 'Comments',
      icon: Icons.comment,
      description: 'Match comments',
    ),
  ];

  @override
  void initState() {
    super.initState();
    teamNumbers = widget.records.map((r) => r.teamNumber).toSet().toList()..sort();
    if (teamNumbers.isNotEmpty) {
      selectedTeam = teamNumbers.first;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<ScoutingRecord> get selectedTeamRecords {
    if (selectedTeam == null) return [];
    return widget.records.where((r) => r.teamNumber == selectedTeam).toList()
      ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Team Visualizations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<int>(
                  value: selectedTeam,
                  hint: const Text('Select Team'),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  dropdownColor: const Color(0xFF2D2D2D),
                  items: teamNumbers.map((team) => DropdownMenuItem(
                    value: team,
                    child: Text(
                      'Team $team',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedTeam = value),
                ),
              ),
            ),
          ],
        ),
        body: selectedTeam == null
            ? const Center(
                child: Text(
                  'Select a team to view analysis',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              )
            : Column(
                children: [
                  _buildTeamSummary(),
                  Expanded(
                    child: _buildChart(),
                  ),
                ],
              ),
        bottomNavigationBar: selectedTeam == null ? null : _buildBottomNav(),
      ),
    );
  }

  Widget _buildTeamSummary() {
    final records = selectedTeamRecords;
    if (records.isEmpty) return const SizedBox.shrink();

    // calculate teleop coral metrics
    final teleopCoralScored = records.map((r) => 
      r.teleopCoralHeight4Success + r.teleopCoralHeight3Success + 
      r.teleopCoralHeight2Success + r.teleopCoralHeight1Success
    ).average();

    final teleopCoralAttempts = records.map((r) => 
      (r.teleopCoralHeight4Success + r.teleopCoralHeight4Failure) +
      (r.teleopCoralHeight3Success + r.teleopCoralHeight3Failure) +
      (r.teleopCoralHeight2Success + r.teleopCoralHeight2Failure) +
      (r.teleopCoralHeight1Success + r.teleopCoralHeight1Failure)
    ).average();
    final teleopSuccessRate = teleopCoralAttempts > 0 ? 
      records.map((r) => 
        (r.teleopCoralHeight4Success + r.teleopCoralHeight3Success + 
         r.teleopCoralHeight2Success + r.teleopCoralHeight1Success) /
        ((r.teleopCoralHeight4Success + r.teleopCoralHeight4Failure) +
         (r.teleopCoralHeight3Success + r.teleopCoralHeight3Failure) +
         (r.teleopCoralHeight2Success + r.teleopCoralHeight2Failure) +
         (r.teleopCoralHeight1Success + r.teleopCoralHeight1Failure))
      ).where((rate) => !rate.isNaN).average() * 100 : 0;

    // calculate auto coral metrics
    final autoCoralScored = records.map((r) => 
      r.autoCoralHeight4Success + r.autoCoralHeight3Success + 
      r.autoCoralHeight2Success + r.autoCoralHeight1Success
    ).average();

    final autoCoralAttempts = records.map((r) => 
      (r.autoCoralHeight4Success + r.autoCoralHeight4Failure) +
      (r.autoCoralHeight3Success + r.autoCoralHeight3Failure) +
      (r.autoCoralHeight2Success + r.autoCoralHeight2Failure) +
      (r.autoCoralHeight1Success + r.autoCoralHeight1Failure)
    ).average();
    final autoSuccessRate = autoCoralAttempts > 0 ? 
      records.map((r) => 
        (r.autoCoralHeight4Success + r.autoCoralHeight3Success + 
         r.autoCoralHeight2Success + r.autoCoralHeight1Success) /
        ((r.autoCoralHeight4Success + r.autoCoralHeight4Failure) +
         (r.autoCoralHeight3Success + r.autoCoralHeight3Failure) +
         (r.autoCoralHeight2Success + r.autoCoralHeight2Failure) +
         (r.autoCoralHeight1Success + r.autoCoralHeight1Failure))
      ).where((rate) => !rate.isNaN).average() * 100 : 0;

    // calculate algae metrics
    final avgAlgaeProcessed = records.map((r) => 
      r.autoAlgaeInProcessor + r.teleopAlgaeProcessed
    ).average();
    
    final avgAlgaeInNet = records.map((r) => 
      r.autoAlgaeInNet + r.teleopAlgaeScoredInNet
    ).average();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetric(
                'Teleop Coral',
                teleopCoralScored.toStringAsFixed(1),
                const Color(0xFF81C784),
              ),
              _buildMetric(
                'Teleop Success',
                '${teleopSuccessRate.round()}%',
                const Color(0xFF81C784),
              ),
              _buildMetric(
                'Auto Coral',
                autoCoralScored.toStringAsFixed(1),
                const Color(0xFFFFB74D),
              ),
              _buildMetric(
                'Auto Success',
                '${autoSuccessRate.round()}%',
                const Color(0xFFFFB74D),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetric(
                'Algae Processed',
                avgAlgaeProcessed.toStringAsFixed(1),
                const Color(0xFFBA68C8),
              ),
              _buildMetric(
                'Algae in Net',
                avgAlgaeInNet.toStringAsFixed(1),
                const Color(0xFFBA68C8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    switch (_selectedIndex) {
      case 0:
        return _buildCoralPlacementChart();
      case 1:
        return _buildCoralOverTimeChart();
      case 2:
        return _buildMatchPerformanceChart();
      case 3:
        return _buildEndgameChart();
      case 4:
        return _buildRankingPointChart();
      case 5:
        return _buildAutoTeleopComparisonChart();
      case 6:
        return _buildCommentsChart();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMatchPerformanceChart() {
    final records = selectedTeamRecords;
    if (records.isEmpty) {
      return _buildEmptyState();
    }

    // Sort records by match number and get unique match numbers
    final matchNumbers = records.map((r) => r.matchNumber).toList()..sort();
    final minMatch = matchNumbers.first;
    final maxMatch = matchNumbers.last;
    
    // Create data points based on selected view
    List<List<FlSpot>> algaeData = List.generate(3, (index) => []);
    final labels = ['Total', 'Processed', 'In Net'];
    final colors = [
      const Color(0xFFBA68C8), // Total - Purple
      const Color(0xFF81C784), // Processed - Green
      const Color(0xFF64B5F6), // In Net - Blue
    ];
    
    if (_algaeView == 'Total') {
      // Show total data for both phases
      for (var record in records) {
        final matchNum = record.matchNumber.toDouble();
        // Total algae (auto + teleop)
        algaeData[0].add(FlSpot(matchNum, 
          (record.autoAlgaeInNet + record.autoAlgaeInProcessor +
           record.teleopAlgaeProcessed + record.teleopAlgaeScoredInNet).toDouble()
        ));
        // Processed (auto + teleop)
        algaeData[1].add(FlSpot(matchNum, 
          (record.autoAlgaeInProcessor + record.teleopAlgaeProcessed).toDouble()
        ));
        // In Net (auto + teleop)
        algaeData[2].add(FlSpot(matchNum, 
          (record.autoAlgaeInNet + record.teleopAlgaeScoredInNet).toDouble()
        ));
      }
    } else {
      // Show data for selected phase (Auto or Teleop)
      for (var record in records) {
        final matchNum = record.matchNumber.toDouble();
        if (_algaeView == 'Auto') {
          // Total auto
          algaeData[0].add(FlSpot(matchNum, 
            (record.autoAlgaeInNet + record.autoAlgaeInProcessor).toDouble()
          ));
          // Individual categories
          algaeData[1].add(FlSpot(matchNum, record.autoAlgaeInProcessor.toDouble()));
          algaeData[2].add(FlSpot(matchNum, record.autoAlgaeInNet.toDouble()));
        } else { // Teleop
          // Total teleop
          algaeData[0].add(FlSpot(matchNum, 
            (record.teleopAlgaeProcessed + record.teleopAlgaeScoredInNet).toDouble()
          ));
          // Individual categories
          algaeData[1].add(FlSpot(matchNum, record.teleopAlgaeProcessed.toDouble()));
          algaeData[2].add(FlSpot(matchNum, record.teleopAlgaeScoredInNet.toDouble()));
        }
      }
    }

    // Calculate maxY for the chart
    final maxY = algaeData.expand((list) => list).map((spot) => spot.y).reduce(max);
    final roundedMaxY = ((maxY / 5).ceil() * 5).toDouble();

    // calculate average and stdev for the total line
    final totalSpots = algaeData[0];  // Use the total line for any view
    final values = totalSpots.map((spot) => spot.y).toList();
    final averageLine = values.average();
    
    // calculate stdev
    final variance = values.map((v) => pow(v - averageLine, 2)).average();
    final stdDev = sqrt(variance).toDouble();
    final upperLine = (averageLine + stdDev).toDouble();
    final lowerLine = max(0, averageLine - stdDev).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Algae Over Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: _algaeView,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  dropdownColor: const Color(0xFF2D2D2D),
                  items: ['Total', 'Teleop', 'Auto'].map((view) => DropdownMenuItem(
                    value: view,
                    child: Text(
                      view,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  )).toList(),
                  onChanged: (value) => setState(() => _algaeView = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _algaeView == 'Total' 
              ? 'Combined auto and teleop algae scoring'
              : '${_algaeView} algae scoring',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              ...List.generate(3, (i) => _buildLegendItem(labels[i], colors[i])),
              const SizedBox(width: 8),
              _buildLegendItem(
                'Avg (${averageLine.toStringAsFixed(1)} ± ${stdDev.toStringAsFixed(1)})',
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    // special styling for the average and stdev lines
                    if ((value - averageLine).abs() < 0.01) {
                      return FlLine(
                        color: Colors.white,
                        strokeWidth: 1,
                        dashArray: [5, 5], // Make it dashed
                      );
                    }
                    if ((value - upperLine).abs() < 0.01 || (value - lowerLine).abs() < 0.01) {
                      return FlLine(
                        color: Colors.white.withOpacity(1.0),
                        strokeWidth: 1,
                        dashArray: [3, 3], // Make it dashed
                      );
                    }
                    return FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final matchNum = value.toInt();
                        if (!matchNumbers.contains(matchNum)) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'M$matchNum',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                minX: minMatch.toDouble(),
                maxX: maxMatch.toDouble(),
                minY: 0,
                maxY: roundedMaxY,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: averageLine,
                      color: Colors.white,
                      strokeWidth: 1,
                      dashArray: [5, 5], // Make it dashed
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        labelResolver: (line) => 'Avg: ${line.y.toStringAsFixed(1)}',
                      ),
                    ),
                    HorizontalLine(
                      y: upperLine,
                      color: Colors.white.withOpacity(1.0),
                      strokeWidth: 1,
                      dashArray: [3, 3], // make it dashed
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        style: TextStyle(
                          color: Colors.white.withOpacity(1.0),
                          fontSize: 10,
                        ),
                        labelResolver: (line) => '+1σ: ${line.y.toStringAsFixed(1)}',
                      ),
                    ),
                    HorizontalLine(
                      y: lowerLine,
                      color: Colors.white.withOpacity(1.0),
                      strokeWidth: 1,
                      dashArray: [3, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        style: TextStyle(
                          color: Colors.white.withOpacity(1.0),
                          fontSize: 10,
                        ),
                        labelResolver: (line) => '-1σ: ${line.y.toStringAsFixed(1)}',
                      ),
                    ),
                  ],
                  extraLinesOnTop: false,
                ),
                backgroundColor: Colors.white.withOpacity(0.05),
                lineBarsData: [
                  // stdev range area
                  LineChartBarData(
                    spots: List.generate(matchNumbers.length, (i) => FlSpot(
                      matchNumbers[i].toDouble(),
                      upperLine,
                    )),
                    isCurved: false,
                    color: Colors.white.withOpacity(0.1),
                    barWidth: 0,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withOpacity(0.05),
                      cutOffY: lowerLine,
                      applyCutOffY: true,
                    ),
                  ),
                  // Regular data lines
                  ...List.generate(3, (i) => 
                    LineChartBarData(
                      spots: algaeData[i],
                      isCurved: false,
                      color: colors[i],
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 5,
                          color: colors[i],
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorder: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    tooltipMargin: 16,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.barIndex;
                        return LineTooltipItem(
                          'Match ${spot.x.toInt()}\n${labels[index]}: ${spot.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: colors[index],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: Colors.white24,
          ),
          SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.height),
        label: 'Coral',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.timeline),
        label: 'Coral OT',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.circle),
        label: 'Algae OT',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.flag),
        label: 'Endgame',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.star),
        label: 'RP',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.compare_arrows),
        label: 'Auto/Teleop',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.comment),
        label: 'Comments',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: items,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF64B5F6),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  Widget _buildCoralPlacementChart() {
    final records = selectedTeamRecords;
    if (records.isEmpty) {
      return _buildEmptyState();
    }

    // calculate auto and teleop averages for each height
    final autoData = [
      records.map((r) => r.autoCoralHeight1Success.toDouble()).average(),
      records.map((r) => r.autoCoralHeight2Success.toDouble()).average(),
      records.map((r) => r.autoCoralHeight3Success.toDouble()).average(),
      records.map((r) => r.autoCoralHeight4Success.toDouble()).average(),
    ];

    final teleopData = [
      records.map((r) => r.teleopCoralHeight1Success.toDouble()).average(),
      records.map((r) => r.teleopCoralHeight2Success.toDouble()).average(),
      records.map((r) => r.teleopCoralHeight3Success.toDouble()).average(),
      records.map((r) => r.teleopCoralHeight4Success.toDouble()).average(),
    ];

    final maxValue = max(
      autoData.reduce(max),
      teleopData.reduce(max)
    );
    final maxY = max(maxValue + 1, 5.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coral Placement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Average successful pieces placed at each height',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildLegendItem('Auto', const Color(0xFF64B5F6)),
              const SizedBox(width: 16),
              _buildLegendItem('Teleop', const Color(0xFF81C784)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        'L${value.toInt() + 1}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(4, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: autoData[index],
                        color: const Color(0xFF64B5F6),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: const Color(0xFF64B5F6).withOpacity(0.1),
                        ),
                      ),
                      BarChartRodData(
                        toY: teleopData[index],
                        color: const Color(0xFF81C784),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: const Color(0xFF81C784).withOpacity(0.1),
                        ),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorder: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    tooltipMargin: 16,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isAuto = rodIndex == 0;
                      final color = isAuto ? const Color(0xFF64B5F6) : const Color(0xFF81C784);
                      final phase = isAuto ? 'Auto' : 'Teleop';
                      return BarTooltipItem(
                        'L${group.x + 1} $phase\n${rod.toY.toStringAsFixed(1)} pieces',
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndgameChart() {
    final records = selectedTeamRecords;
    if (records.isEmpty) {
      return _buildEmptyState();
    }

    final hangRate = records.where((r) => r.endgameCageHang != 'None').length / records.length;
    final bargeRate = records.where((r) => r.endgameReturnedToBarge).length / records.length;
    final bargeRPRate = records.where((r) => r.endgameBargeRankingPoint).length / records.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Endgame Success',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Success rates for endgame tasks',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildLegendItem('Cage Hang', const Color(0xFFFFB74D)),
              const SizedBox(width: 16),
              _buildLegendItem('Barge Return', const Color(0xFFBA68C8)),
              const SizedBox(width: 16),
              _buildLegendItem('Barge RP', const Color(0xFF64B5F6)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 0.2,
                      getTitlesWidget: (value, meta) => Text(
                        '${(value * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Cage Hang', 'Barge Return', 'Barge RP'];
                        return Text(
                          labels[value.toInt()],
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: hangRate,
                        color: const Color(0xFFFFB74D),
                        width: 32,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 1,
                          color: const Color(0xFFFFB74D).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: bargeRate,
                        color: const Color(0xFFBA68C8),
                        width: 32,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 1,
                          color: const Color(0xFFBA68C8).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: bargeRPRate,
                        color: const Color(0xFF64B5F6),
                        width: 32,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 1,
                          color: const Color(0xFF64B5F6).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorder: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    tooltipMargin: 16,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final labels = ['Cage Hang', 'Barge Return', 'Barge RP'];
                      final colors = [
                        const Color(0xFFFFB74D),
                        const Color(0xFFBA68C8),
                        const Color(0xFF64B5F6),
                      ];
                      return BarTooltipItem(
                        '${labels[groupIndex]}\n${(rod.toY * 100).round()}%',
                        TextStyle(
                          color: colors[groupIndex],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingPointChart() {
    final records = selectedTeamRecords;
    if (records.isEmpty) return const Center(child: Text('No data available', style: TextStyle(color: Colors.grey)));

    final coralRP = records.where((r) => r.teleopCoralRankingPoint).length / records.length;
    final bargeRP = records.where((r) => r.endgameBargeRankingPoint).length / records.length;
    final coOpRP = records.where((r) => r.otherCoOpPoint).length / records.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Ranking Point Success Rates',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Coral', Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem('Barge', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('Co-Op', Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 0.2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).round()}%',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Coral RP';
                            break;
                          case 1:
                            text = 'Barge RP';
                            break;
                          case 2:
                            text = 'Co-Op RP';
                            break;
                          default:
                            text = '';
                        }
                        return Text(
                          text,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: coralRP,
                        color: Colors.blue.withOpacity(0.8),
                        width: 32,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 1,
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: bargeRP,
                        color: Colors.green.withOpacity(0.8),
                        width: 32,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 1,
                          color: Colors.green.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: coOpRP,
                        color: Colors.orange.withOpacity(0.8),
                        width: 32,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 1,
                          color: Colors.orange.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorder: const BorderSide(color: Colors.transparent),
                    tooltipMargin: 16,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String label;
                      Color color;
                      switch (groupIndex) {
                        case 0:
                          label = 'Coral RP';
                          color = Colors.blue;
                          break;
                        case 1:
                          label = 'Barge RP';
                          color = Colors.green;
                          break;
                        case 2:
                          label = 'Co-Op RP';
                          color = Colors.orange;
                          break;
                        default:
                          label = '';
                          color = Colors.grey;
                      }
                      return BarTooltipItem(
                        '$label: ${(rod.toY * 100).round()}%',
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoTeleopComparisonChart() {
    final records = selectedTeamRecords;
    if (records.isEmpty) {
      return _buildEmptyState();
    }

    // Sort records by match number and get unique match numbers
    final matchNumbers = records.map((r) => r.matchNumber).toList()..sort();
    final minMatch = matchNumbers.first;
    final maxMatch = matchNumbers.last;
    
    // create a map of match number to scores to handle potential duplicates
    Map<int, int> autoScoresByMatch = {};
    Map<int, int> teleopScoresByMatch = {};
    
    for (var record in records) {
      autoScoresByMatch[record.matchNumber] = 
        record.autoCoralHeight4Success + record.autoCoralHeight3Success + 
        record.autoCoralHeight2Success + record.autoCoralHeight1Success +
        record.autoAlgaeInNet + record.autoAlgaeInProcessor;
      
      teleopScoresByMatch[record.matchNumber] = 
        record.teleopCoralHeight4Success + record.teleopCoralHeight3Success + 
        record.teleopCoralHeight2Success + record.teleopCoralHeight1Success +
        record.teleopAlgaeScoredInNet + record.teleopAlgaeProcessed;
    }
    
    final maxY = max(
      autoScoresByMatch.values.isEmpty ? 0 : autoScoresByMatch.values.reduce(max),
      teleopScoresByMatch.values.isEmpty ? 0 : teleopScoresByMatch.values.reduce(max)
    ).toDouble();
    final roundedMaxY = ((maxY / 5).ceil() * 5).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Auto vs Teleop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total scoring by phase',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildLegendItem('Auto', const Color(0xFFFFB74D)),
              const SizedBox(width: 16),
              _buildLegendItem('Teleop', const Color(0xFFBA68C8)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 5,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final matchNum = value.toInt();
                        if (!matchNumbers.contains(matchNum)) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'M$matchNum',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                minX: minMatch.toDouble(),
                maxX: maxMatch.toDouble(),
                minY: 0,
                maxY: roundedMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: matchNumbers.map((matchNum) => FlSpot(
                      matchNum.toDouble(),
                      autoScoresByMatch[matchNum]!.toDouble(),
                    )).toList(),
                    isCurved: false,
                    color: const Color(0xFFFFB74D),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: const Color(0xFFFFB74D),
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: matchNumbers.map((matchNum) => FlSpot(
                      matchNum.toDouble(),
                      teleopScoresByMatch[matchNum]!.toDouble(),
                    )).toList(),
                    isCurved: false,
                    color: const Color(0xFFBA68C8),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: const Color(0xFFBA68C8),
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorder: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    tooltipMargin: 16,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isAuto = spot.bar.color == const Color(0xFFFFB74D);
                        return LineTooltipItem(
                          'Match ${spot.x.toInt()}\n${spot.y.toStringAsFixed(1)} ${isAuto ? "Auto" : "Teleop"}',
                          TextStyle(
                            color: spot.bar.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoralOverTimeChart() {
    final records = selectedTeamRecords;
    if (records.isEmpty) {
      return _buildEmptyState();
    }

    // Sort records by match number and get unique match numbers
    final matchNumbers = records.map((r) => r.matchNumber).toList()..sort();
    final minMatch = matchNumbers.first;
    final maxMatch = matchNumbers.last;

    // Create data points based on selected view
    List<List<FlSpot>> coralData = List.generate(5, (index) => []);
    final labels = ['Total', 'L4', 'L3', 'L2', 'L1'];
    final colors = [
      const Color(0xFFBA68C8), // Total - Purple
      const Color(0xFFE57373), // L4 - Red
      const Color(0xFF81C784), // L3 - Green
      const Color(0xFF64B5F6), // L2 - Blue
      const Color(0xFFFFB74D), // L1 - Orange
    ];
    
    if (_coralView == 'Total') {
      // Show total data for both phases
      for (var record in records) {
        final matchNum = record.matchNumber.toDouble();
        // Total coral (auto + teleop)
        coralData[0].add(FlSpot(matchNum, 
          (record.autoCoralHeight4Success + record.autoCoralHeight3Success + 
           record.autoCoralHeight2Success + record.autoCoralHeight1Success +
           record.teleopCoralHeight4Success + record.teleopCoralHeight3Success + 
           record.teleopCoralHeight2Success + record.teleopCoralHeight1Success).toDouble()
        ));
        // L4 (auto + teleop)
        coralData[1].add(FlSpot(matchNum, 
          (record.autoCoralHeight4Success + record.teleopCoralHeight4Success).toDouble()
        ));
        // L3 (auto + teleop)
        coralData[2].add(FlSpot(matchNum, 
          (record.autoCoralHeight3Success + record.teleopCoralHeight3Success).toDouble()
        ));
        // L2 (auto + teleop)
        coralData[3].add(FlSpot(matchNum, 
          (record.autoCoralHeight2Success + record.teleopCoralHeight2Success).toDouble()
        ));
        // L1 (auto + teleop)
        coralData[4].add(FlSpot(matchNum, 
          (record.autoCoralHeight1Success + record.teleopCoralHeight1Success).toDouble()
        ));
      }
    } else {
      // Show data for selected phase (Auto or Teleop)
      for (var record in records) {
        final matchNum = record.matchNumber.toDouble();
        if (_coralView == 'Auto') {
          // total auto
          coralData[0].add(FlSpot(matchNum, 
            (record.autoCoralHeight4Success + 
             record.autoCoralHeight3Success + 
             record.autoCoralHeight2Success + 
             record.autoCoralHeight1Success).toDouble()
          ));
          // individual heights
          coralData[1].add(FlSpot(matchNum, record.autoCoralHeight4Success.toDouble()));
          coralData[2].add(FlSpot(matchNum, record.autoCoralHeight3Success.toDouble()));
          coralData[3].add(FlSpot(matchNum, record.autoCoralHeight2Success.toDouble()));
          coralData[4].add(FlSpot(matchNum, record.autoCoralHeight1Success.toDouble()));
        } else { // Teleop
          // Total teleop
          coralData[0].add(FlSpot(matchNum, 
            (record.teleopCoralHeight4Success + 
             record.teleopCoralHeight3Success + 
             record.teleopCoralHeight2Success + 
             record.teleopCoralHeight1Success).toDouble()
          ));
          // Individual heights
          coralData[1].add(FlSpot(matchNum, record.teleopCoralHeight4Success.toDouble()));
          coralData[2].add(FlSpot(matchNum, record.teleopCoralHeight3Success.toDouble()));
          coralData[3].add(FlSpot(matchNum, record.teleopCoralHeight2Success.toDouble()));
          coralData[4].add(FlSpot(matchNum, record.teleopCoralHeight1Success.toDouble()));
        }
      }
    }

    // Calculate maxY for the chart
    final maxY = coralData.expand((list) => list).map((spot) => spot.y).reduce(max);
    final roundedMaxY = ((maxY / 5).ceil() * 5).toDouble();

    // calculate average and stdev for the total line
    final totalSpots = coralData[0];  // Use the total line for any view
    final values = totalSpots.map((spot) => spot.y).toList();
    final averageLine = values.average();
    
    // calculate stdev
    final variance = values.map((v) => pow(v - averageLine, 2)).average();
    final stdDev = sqrt(variance).toDouble();
    final upperLine = (averageLine + stdDev).toDouble();
    final lowerLine = max(0, averageLine - stdDev).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Coral Over Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: _coralView,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  dropdownColor: const Color(0xFF2D2D2D),
                  items: ['Total', 'Teleop', 'Auto'].map((view) => DropdownMenuItem(
                    value: view,
                    child: Text(
                      view,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  )).toList(),
                  onChanged: (value) => setState(() => _coralView = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _coralView == 'Total' 
              ? 'Combined auto and teleop coral scoring by height'
              : '${_coralView} coral scoring by height',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              ...List.generate(5, (i) => _buildLegendItem(labels[i], colors[i])),
              const SizedBox(width: 8),
              _buildLegendItem(
                'Avg (${averageLine.toStringAsFixed(1)} ± ${stdDev.toStringAsFixed(1)})',
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    // special styling for the average and stdev lines
                    if ((value - averageLine).abs() < 0.01) {
                      return FlLine(
                        color: Colors.white,
                        strokeWidth: 1,
                        dashArray: [5, 5], // Make it dashed
                      );
                    }
                    if ((value - upperLine).abs() < 0.01 || (value - lowerLine).abs() < 0.01) {
                      return FlLine(
                        color: Colors.white.withOpacity(1.0),
                        strokeWidth: 1,
                        dashArray: [3, 3], // Make it dashed
                      );
                    }
                    return FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final matchNum = value.toInt();
                        if (!matchNumbers.contains(matchNum)) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'M$matchNum',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                minX: minMatch.toDouble(),
                maxX: maxMatch.toDouble(),
                minY: 0,
                maxY: roundedMaxY,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: averageLine,
                      color: Colors.white,
                      strokeWidth: 1,
                      dashArray: [5, 5], // Make it dashed
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        labelResolver: (line) => 'Avg: ${line.y.toStringAsFixed(1)}',
                      ),
                    ),
                    HorizontalLine(
                      y: upperLine,
                      color: Colors.white.withOpacity(1.0),
                      strokeWidth: 1,
                      dashArray: [3, 3], // make it dashed
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        style: TextStyle(
                          color: Colors.white.withOpacity(1.0),
                          fontSize: 10,
                        ),
                        labelResolver: (line) => '+1σ: ${line.y.toStringAsFixed(1)}',
                      ),
                    ),
                    HorizontalLine(
                      y: lowerLine,
                      color: Colors.white.withOpacity(1.0),
                      strokeWidth: 1,
                      dashArray: [3, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        style: TextStyle(
                          color: Colors.white.withOpacity(1.0),
                          fontSize: 10,
                        ),
                        labelResolver: (line) => '-1σ: ${line.y.toStringAsFixed(1)}',
                      ),
                    ),
                  ],
                  extraLinesOnTop: false,
                ),
                backgroundColor: Colors.white.withOpacity(0.05),
                lineBarsData: [
                  // stdev range area
                  LineChartBarData(
                    spots: List.generate(matchNumbers.length, (i) => FlSpot(
                      matchNumbers[i].toDouble(),
                      upperLine,
                    )),
                    isCurved: false,
                    color: Colors.white.withOpacity(0.1),
                    barWidth: 0,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withOpacity(0.05),
                      cutOffY: lowerLine,
                      applyCutOffY: true,
                    ),
                  ),
                  // Regular data lines
                  ...List.generate(5, (i) => 
                    LineChartBarData(
                      spots: coralData[i],
                      isCurved: false,
                      color: colors[i],
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 5,
                          color: colors[i],
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorder: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    tooltipMargin: 16,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.barIndex;
                        return LineTooltipItem(
                          'Match ${spot.x.toInt()}\n${labels[index]}: ${spot.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: colors[index],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsChart() {
    final records = selectedTeamRecords;
    if (records.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Comments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comments from each match',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Match ${record.matchNumber}',
                              style: const TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            record.matchType,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.purple),
                            onPressed: () => _showEditCommentDialog(context, record),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        record.otherComments.isEmpty ? 'No comments' : record.otherComments,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
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

  Future<void> _showEditCommentDialog(BuildContext context, ScoutingRecord record) async {
    final commentController = TextEditingController(text: record.otherComments);
    // Set the cursor to the end of the text
    commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: commentController.text.length),
    );
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Comments for Match ${record.matchNumber}'),
        content: TextField(
          controller: commentController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter comments...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 14),
          textInputAction: TextInputAction.done,
          onTapOutside: (_) {
            // dismiss keyboard when tapping outside
            FocusScope.of(context).unfocus();
          },
          onSubmitted: (_) {
            // dismiss keyboard when submitting
            FocusScope.of(context).unfocus();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, commentController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // clean up the controller
    commentController.dispose();

    if (result != null) {
      // Create a new record with updated comments
      final updatedRecord = ScoutingRecord(
        timestamp: record.timestamp,
        matchNumber: record.matchNumber,
        matchType: record.matchType,
        teamNumber: record.teamNumber,
        isRedAlliance: record.isRedAlliance,
        autoTaxis: record.autoTaxis,
        autoCoralPreloaded: record.autoCoralPreloaded,
        autoAlgaeRemoved: record.autoAlgaeRemoved,
        autoCoralHeight4Success: record.autoCoralHeight4Success,
        autoCoralHeight4Failure: record.autoCoralHeight4Failure,
        autoCoralHeight3Success: record.autoCoralHeight3Success,
        autoCoralHeight3Failure: record.autoCoralHeight3Failure,
        autoCoralHeight2Success: record.autoCoralHeight2Success,
        autoCoralHeight2Failure: record.autoCoralHeight2Failure,
        autoCoralHeight1Success: record.autoCoralHeight1Success,
        autoCoralHeight1Failure: record.autoCoralHeight1Failure,
        autoAlgaeInNet: record.autoAlgaeInNet,
        autoAlgaeInProcessor: record.autoAlgaeInProcessor,
        teleopCoralHeight4Success: record.teleopCoralHeight4Success,
        teleopCoralHeight4Failure: record.teleopCoralHeight4Failure,
        teleopCoralHeight3Success: record.teleopCoralHeight3Success,
        teleopCoralHeight3Failure: record.teleopCoralHeight3Failure,
        teleopCoralHeight2Success: record.teleopCoralHeight2Success,
        teleopCoralHeight2Failure: record.teleopCoralHeight2Failure,
        teleopCoralHeight1Success: record.teleopCoralHeight1Success,
        teleopCoralHeight1Failure: record.teleopCoralHeight1Failure,
        teleopCoralRankingPoint: record.teleopCoralRankingPoint,
        teleopAlgaeRemoved: record.teleopAlgaeRemoved,
        teleopAlgaeProcessorAttempts: record.teleopAlgaeProcessorAttempts,
        teleopAlgaeProcessed: record.teleopAlgaeProcessed,
        teleopAlgaeScoredInNet: record.teleopAlgaeScoredInNet,
        teleopCanPickupAlgae: record.teleopCanPickupAlgae,
        teleopCoralPickupMethod: record.teleopCoralPickupMethod,
        endgameReturnedToBarge: record.endgameReturnedToBarge,
        endgameCageHang: record.endgameCageHang,
        endgameBargeRankingPoint: record.endgameBargeRankingPoint,
        otherCoOpPoint: record.otherCoOpPoint,
        otherBreakdown: record.otherBreakdown,
        otherComments: result,
        cageType: record.cageType,
        coralPreloaded: record.coralPreloaded,
        taxis: record.taxis,
        algaeRemoved: record.algaeRemoved,
        coralPlaced: record.coralPlaced,
        rankingPoint: record.rankingPoint,
        canPickupCoral: record.canPickupCoral,
        canPickupAlgae: record.canPickupAlgae,
        algaeScoredInNet: record.algaeScoredInNet,
        coralRankingPoint: record.coralRankingPoint,
        algaeProcessed: record.algaeProcessed,
        processedAlgaeScored: record.processedAlgaeScored,
        processorCycles: record.processorCycles,
        coOpPoint: record.coOpPoint,
        returnedToBarge: record.returnedToBarge,
        cageHang: record.cageHang,
        bargeRankingPoint: record.bargeRankingPoint,
        breakdown: record.breakdown,
        comments: result,
        coralPickupMethod: record.coralPickupMethod,
        feederStation: record.feederStation,
        coralOnReefHeight1: record.coralOnReefHeight1,
        coralOnReefHeight2: record.coralOnReefHeight2,
        coralOnReefHeight3: record.coralOnReefHeight3,
        coralOnReefHeight4: record.coralOnReefHeight4,
        robotPath: record.robotPath,
      );

      // Update the record in the database
      final records = await DataManager.getRecords();
      final index = records.indexWhere((r) => r.timestamp == record.timestamp);
      if (index != -1) {
        records[index] = updatedRecord;
        await DatabaseHelper.instance.saveRecords(records);
        
        // Refresh the widget
        setState(() {});
      }
    }
  }
}

class ChartType {
  final String title;
  final IconData icon;
  final String description;

  const ChartType({
    required this.title,
    required this.icon,
    required this.description,
  });
}

extension IterableNumExtension on Iterable<num> {
  double average() {
    if (isEmpty) return 0;
    return map((e) => e.toDouble()).reduce((a, b) => a + b) / length;
  }
}

class DetailedChartPage extends StatelessWidget {
  final String title;
  final Widget chart;

  const DetailedChartPage({
    Key? key,
    required this.title,
    required this.chart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Force landscape orientation for better chart viewing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Reset to portrait orientation when leaving
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: chart,
      ),
    );
  }
} 