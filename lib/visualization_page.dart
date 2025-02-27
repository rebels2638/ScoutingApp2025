import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'dart:math' show max, min;
import 'package:flutter/services.dart';

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
  
  final List<ChartType> _chartTypes = [
    ChartType(
      title: 'Match Performance',
      icon: Icons.trending_up,
      description: 'Scoring progression across matches',
    ),
    ChartType(
      title: 'Coral Placement',
      icon: Icons.height,
      description: 'Average pieces at each height',
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

    final avgTotal = records.map((r) => 
      r.algaeRemoved + r.algaeScoredInNet + r.processedAlgaeScored
    ).average();

    final hangRate = records.where((r) => r.cageHang != 'None').length / records.length * 100;
    final rpRate = records.where((r) => 
      r.rankingPoint || r.coralRankingPoint || r.bargeRankingPoint
    ).length / (records.length * 3) * 100;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetric(
            'Matches',
            records.length.toString(),
            const Color(0xFF64B5F6),
          ),
          _buildMetric(
            'Avg Algae',
            avgTotal.toStringAsFixed(1),
            const Color(0xFF81C784),
          ),
          _buildMetric(
            'Hang Rate',
            '${hangRate.round()}%',
            const Color(0xFFFFB74D),
          ),
          _buildMetric(
            'RP Rate',
            '${rpRate.round()}%',
            const Color(0xFFBA68C8),
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    switch (_selectedIndex) {
      case 0:
        return _buildMatchPerformanceChart();
      case 1:
        return _buildCoralPlacementChart();
      case 2:
        return _buildEndgameChart();
      case 3:
        return _buildRankingPointChart();
      case 4:
        return _buildAutoTeleopComparisonChart();
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
    
    final maxY = records.map((r) => 
      r.algaeRemoved + r.algaeScoredInNet + r.processedAlgaeScored
    ).reduce(max).toDouble();
    final roundedMaxY = ((maxY / 5).ceil() * 5).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('Total Algae', const Color(0xFF64B5F6)),
              const SizedBox(width: 16),
              _buildLegendItem('Processed', const Color(0xFF81C784)),
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
                    spots: records.map((r) => FlSpot(
                      r.matchNumber.toDouble(),
                      (r.algaeRemoved + r.algaeScoredInNet + r.processedAlgaeScored).toDouble(),
                    )).toList(),
                    isCurved: true,
                    color: const Color(0xFF64B5F6),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: const Color(0xFF64B5F6),
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: records.map((r) => FlSpot(
                      r.matchNumber.toDouble(),
                      r.processedAlgaeScored.toDouble(),
                    )).toList(),
                    isCurved: true,
                    color: const Color(0xFF81C784),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: const Color(0xFF81C784),
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
                        final isTotal = spot.bar.color == const Color(0xFF64B5F6);
                        return LineTooltipItem(
                          'Match ${spot.x.toInt()}\n${spot.y.toStringAsFixed(1)} ${isTotal ? "Total" : "Processed"}',
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
        icon: Icon(Icons.show_chart),
        label: 'Performance',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.height),
        label: 'Coral',
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

    final data = [
      records.map((r) => r.coralOnReefHeight1.toDouble()).average(),
      records.map((r) => r.coralOnReefHeight2.toDouble()).average(),
      records.map((r) => r.coralOnReefHeight3.toDouble()).average(),
      records.map((r) => r.coralOnReefHeight4.toDouble()).average(),
    ];

    final maxValue = data.reduce(max);
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
            'Average pieces placed at each height',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
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
                        'Height ${value.toInt() + 1}',
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
                barGroups: data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: const Color(0xFF64B5F6),
                        width: 32,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: const Color(0xFF64B5F6).withOpacity(0.1),
                        ),
                      ),
                    ],
                  );
                }).toList(),
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
                      return BarTooltipItem(
                        'Height ${groupIndex + 1}\n${rod.toY.toStringAsFixed(1)} pieces',
                        const TextStyle(
                          color: Color(0xFF64B5F6),
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

    final hangRate = records.where((r) => r.cageHang != 'None').length / records.length;
    final bargeRate = records.where((r) => r.returnedToBarge).length / records.length;

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
            'Success rates for cage hang and barge return',
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
                      getTitlesWidget: (value, meta) => Text(
                        value == 0 ? 'Cage Hang' : 'Barge Return',
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
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: hangRate,
                        color: const Color(0xFFFFB74D),
                        width: 40,
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
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 1,
                          color: const Color(0xFFBA68C8).withOpacity(0.1),
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
                      final isHang = groupIndex == 0;
                      final color = isHang ? const Color(0xFFFFB74D) : const Color(0xFFBA68C8);
                      final label = isHang ? 'Cage Hang' : 'Barge Return';
                      return BarTooltipItem(
                        '$label\n${(rod.toY * 100).round()}%',
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

  Widget _buildRankingPointChart() {
    final records = selectedTeamRecords;
    if (records.isEmpty) return const Center(child: Text('No data available', style: TextStyle(color: Colors.grey)));

    final autoRP = records.where((r) => r.rankingPoint).length / records.length;
    final coralRP = records.where((r) => r.coralRankingPoint).length / records.length;
    final bargeRP = records.where((r) => r.bargeRankingPoint).length / records.length;

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
              _buildLegendItem('Auto', Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem('Coral', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('Barge', Colors.orange),
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
                            text = 'Auto RP';
                            break;
                          case 1:
                            text = 'Coral RP';
                            break;
                          case 2:
                            text = 'Barge RP';
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
                        toY: autoRP.toDouble(),
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
                        toY: coralRP.toDouble(),
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
                        toY: bargeRP.toDouble(),
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
                          label = 'Auto RP';
                          color = Colors.blue;
                          break;
                        case 1:
                          label = 'Coral RP';
                          color = Colors.green;
                          break;
                        case 2:
                          label = 'Barge RP';
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
    
    final maxY = records.map((r) => 
      max(r.algaeRemoved, r.algaeScoredInNet)
    ).reduce(max).toDouble();
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
            'Scoring comparison by phase',
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
                    spots: records.map((r) => FlSpot(
                      r.matchNumber.toDouble(),
                      r.algaeRemoved.toDouble(),
                    )).toList(),
                    isCurved: true,
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
                    spots: records.map((r) => FlSpot(
                      r.matchNumber.toDouble(),
                      r.algaeScoredInNet.toDouble(),
                    )).toList(),
                    isCurved: true,
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