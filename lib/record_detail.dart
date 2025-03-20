import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'data.dart'; // for ScoutingRecord
import 'drawing_page.dart';
import 'drawing_page.dart' show DrawingPage, DrawingLine;
import 'database_helper.dart';

class RecordDetailPage extends StatelessWidget {
  final ScoutingRecord record;

  const RecordDetailPage({
    Key? key, 
    required this.record,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<DrawingLine> drawingLines = [];
    if (record.robotPath != null && record.robotPath!.isNotEmpty) {
      drawingLines = record.robotPath!.map((map) => DrawingLine.fromJson(map)).toList();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Details'),
        actions: [
          if (drawingLines.isNotEmpty)
            IconButton(
              icon: Icon(Icons.map),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DrawingPage(
                      isRedAlliance: record.isRedAlliance,
                      readOnly: true,
                      initialDrawing: record.robotPath,
                      imagePath: record.robotPath?.firstOrNull?['imagePath'] as String?,
                    ),
                  ),
                );
              },
              tooltip: 'View Auto Path',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Match Header
            _buildMatchHeader(context),
            
            // Stats Sections
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAutoSection(context),
                  const SizedBox(height: 16),
                  _buildTeleopSection(context),
                  const SizedBox(height: 16),
                  _buildEndgameSection(context),
                  const SizedBox(height: 16),
                  if (record.comments.isNotEmpty)
                    _buildCommentsSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: record.isRedAlliance ? AppColors.redAlliance : AppColors.blueAlliance,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Team ${record.teamNumber}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${record.matchType} Match ${record.matchNumber}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.timestamp,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Autonomous',
      icon: Icons.auto_awesome,
      color: Colors.blue,
      children: [
        _buildStatRow('Starting Configuration', [
          _buildStat('Coral Preloaded', record.autoCoralPreloaded ? 'Yes' : 'No'),
        ]),
        _buildStatRow('Movement', [
          _buildStat('Taxis', record.autoTaxis ? 'Yes' : 'No'),
          _buildStat('Auto Path', record.robotPath != null ? 'Drawn' : 'None'),
        ]),
        _buildStatRow('Algae Scoring', [
          _buildStat('Algae Removed', record.autoAlgaeRemoved.toString()),
          _buildStat('Algae in Net', record.autoAlgaeInNet.toString()),
          _buildStat('Algae in Processor', record.autoAlgaeInProcessor.toString()),
        ]),
        _buildStatRow('Coral Height 1', [
          _buildStat('Success', record.autoCoralHeight1Success.toString()),
          _buildStat('Failure', record.autoCoralHeight1Failure.toString()),
        ]),
        _buildStatRow('Coral Height 2', [
          _buildStat('Success', record.autoCoralHeight2Success.toString()),
          _buildStat('Failure', record.autoCoralHeight2Failure.toString()),
        ]),
        _buildStatRow('Coral Height 3', [
          _buildStat('Success', record.autoCoralHeight3Success.toString()),
          _buildStat('Failure', record.autoCoralHeight3Failure.toString()),
        ]),
        _buildStatRow('Coral Height 4', [
          _buildStat('Success', record.autoCoralHeight4Success.toString()),
          _buildStat('Failure', record.autoCoralHeight4Failure.toString()),
        ]),
      ],
    );
  }

  Widget _buildTeleopSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Teleop',
      icon: Icons.sports_esports,
      color: Colors.green,
      children: [
        _buildStatRow('Algae Scoring', [
          _buildStat('Removed', record.teleopAlgaeRemoved.toString()),
          _buildStat('In Net', record.teleopAlgaeScoredInNet.toString()),
          _buildStat('Processed', record.teleopAlgaeProcessed.toString()),
        ]),
        _buildStatRow('Coral Height 1', [
          _buildStat('Success', record.teleopCoralHeight1Success.toString()),
          _buildStat('Failure', record.teleopCoralHeight1Failure.toString()),
        ]),
        _buildStatRow('Coral Height 2', [
          _buildStat('Success', record.teleopCoralHeight2Success.toString()),
          _buildStat('Failure', record.teleopCoralHeight2Failure.toString()),
        ]),
        _buildStatRow('Coral Height 3', [
          _buildStat('Success', record.teleopCoralHeight3Success.toString()),
          _buildStat('Failure', record.teleopCoralHeight3Failure.toString()),
        ]),
        _buildStatRow('Coral Height 4', [
          _buildStat('Success', record.teleopCoralHeight4Success.toString()),
          _buildStat('Failure', record.teleopCoralHeight4Failure.toString()),
        ]),
        _buildStatRow('Capabilities', [
          _buildStat('Can Pickup Algae', record.teleopCanPickupAlgae ? 'Yes' : 'No'),
          _buildStat('Coral Pickup Method', record.teleopCoralPickupMethod),
        ]),
        _buildStatRow('Points', [
          _buildStat('Coral Ranking Point', record.teleopCoralRankingPoint ? 'Yes' : 'No'),
        ]),
      ],
    );
  }

  Widget _buildEndgameSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Endgame',
      icon: Icons.flag,
      color: Colors.orange,
      children: [
        _buildStatRow('Performance', [
          _buildStat('Cage Hang', record.endgameCageHang),
          _buildStat('Return to Barge', record.endgameReturnedToBarge ? 'Yes' : 'No'),
        ]),
        _buildStatRow('Points', [
          _buildStat('Barge Ranking Point', record.endgameBargeRankingPoint ? 'Yes' : 'No'),
          _buildStat('Co-Op Point', record.otherCoOpPoint ? 'Yes' : 'No'),
        ]),
        _buildStatRow('Issues', [
          _buildStat('Breakdown', record.otherBreakdown ? 'Yes' : 'No',
              color: record.otherBreakdown ? Colors.red : null),
        ]),
      ],
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Comments',
      icon: Icons.comment,
      color: Colors.purple,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            record.otherComments,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: color.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, List<Widget> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final defaultColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;
        final textColor = isDark ? Colors.white : Colors.black87;
        
        final effectiveColor = color ?? defaultColor;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: effectiveColor.withOpacity(isDark ? 0.3 : 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: effectiveColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color ?? textColor,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
} 