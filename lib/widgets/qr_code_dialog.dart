import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data.dart';

class QRCodeDialog extends StatefulWidget {
  final ScoutingRecord record;

  const QRCodeDialog({
    Key? key,
    required this.record,
  }) : super(key: key);

  @override
  State<QRCodeDialog> createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<QRCodeDialog> {
  late bool dontShowAgain;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      dontShowAgain = prefs.getBool('skip_drawing_qr_warning') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Create a minimal array format to reduce data size
    final List<dynamic> qrData = [
      widget.record.timestamp,                    // [0]
      widget.record.matchNumber,                  // [1]
      widget.record.matchType,                    // [2]
      widget.record.teamNumber,                   // [3]
      widget.record.isRedAlliance ? 1 : 0,        // [4]
      widget.record.cageType,                     // [5]
      widget.record.autoCoralPreloaded ? 1 : 0,   // [6]
      widget.record.autoTaxis ? 1 : 0,            // [7]
      widget.record.autoAlgaeRemoved,             // [8]
      widget.record.autoAlgaeInNet,               // [9]
      widget.record.autoAlgaeInProcessor,         // [10]
      widget.record.teleopCoralHeight3Success,    // [11]
      widget.record.teleopCoralHeight3Failure,    // [12]
      widget.record.autoCoralHeight1Success,      // [13]
      widget.record.autoCoralHeight1Failure,      // [14]
      widget.record.autoCoralHeight2Success,      // [15]
      widget.record.autoCoralHeight2Failure,      // [16]
      widget.record.autoCoralHeight3Success,      // [17]
      widget.record.autoCoralHeight3Failure,      // [18]
      widget.record.autoCoralHeight4Success,      // [19]
      widget.record.autoCoralHeight4Failure,      // [20]
      widget.record.teleopCoralHeight4Success,    // [21]
      widget.record.teleopCoralHeight4Failure,    // [22]
      widget.record.teleopCoralHeight2Success,    // [23]
      widget.record.teleopCoralHeight2Failure,    // [24]
      widget.record.teleopCoralHeight1Success,    // [25]
      widget.record.teleopCoralHeight1Failure,    // [26]
      widget.record.teleopCoralRankingPoint ? 1 : 0, // [27]
      widget.record.teleopAlgaeRemoved,           // [28]
      widget.record.teleopAlgaeProcessorAttempts, // [29]
      widget.record.teleopAlgaeProcessed,         // [30]
      widget.record.teleopAlgaeScoredInNet,       // [31]
      widget.record.teleopCanPickupAlgae ? 1 : 0, // [32]
      widget.record.teleopCoralPickupMethod,      // [33]
      widget.record.endgameReturnedToBarge ? 1 : 0, // [34]
      widget.record.endgameCageHang,              // [35]
      widget.record.endgameBargeRankingPoint ? 1 : 0, // [36]
      widget.record.otherCoOpPoint ? 1 : 0,       // [37]
      widget.record.otherBreakdown ? 1 : 0,       // [38]
      widget.record.otherComments,                // [39]
      widget.record.robotPath                     // [40]
    ];

    final jsonStr = jsonEncode(qrData);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Team ${widget.record.teamNumber}\nMatch ${widget.record.matchNumber}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.record.robotPath != null && !dontShowAgain) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Warning: Auto path drawing will not be included in QR code',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: dontShowAgain,
                            onChanged: (value) async {
                              setState(() {
                                dontShowAgain = value ?? false;
                              });
                              if (value ?? false) {
                                await prefs.setBool('skip_drawing_qr_warning', true);
                              }
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "Don't show this warning again",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: QrImageView(
                  data: jsonStr,
                  version: QrVersions.auto,
                  size: 280,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                  gapless: true,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan this QR code to import the match data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 