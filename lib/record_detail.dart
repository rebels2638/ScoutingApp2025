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

  // Helper to build a key-value tile.
  Widget _buildDetailTile(String title, String value) {
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convert saved drawing data if provided
    List<DrawingLine> drawingLines = [];
    if (record.robotPath != null && record.robotPath!.isNotEmpty) {
      // Assuming each map in robotPath can be converted using DrawingLine.fromJson
      drawingLines = record.robotPath!
          .map((map) => DrawingLine.fromJson(map))
          .toList();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team ${record.teamNumber}'),
            Text('${record.matchType} Match ${record.matchNumber}'),
            _buildDetailTile("Timestamp", record.timestamp),
            _buildDetailTile("Match Type", record.matchType),
            _buildDetailTile("Alliance", record.isRedAlliance ? "Red" : "Blue"),
            _buildDetailTile("Cage Type", record.cageType),
            _buildDetailTile("Coral Preloaded", record.coralPreloaded ? "Yes" : "No"),
            // ... other detail tiles ...
            if (record.robotPath != null && record.robotPath!.isNotEmpty) ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DrawingPage(
                        isRedAlliance: record.isRedAlliance,
                        readOnly: true,
                        initialLines: drawingLines,
                      ),
                    ),
                  );
                },
                child: Text("View Drawing"),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 