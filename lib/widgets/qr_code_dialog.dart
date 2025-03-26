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
      // match info
      widget.record.timestamp,
      widget.record.matchNumber,
      widget.record.matchType,
      widget.record.teamNumber,
      widget.record.isRedAlliance ? 1 : 0,
      widget.record.cageType,

      // auto
      widget.record.autoCoralPreloaded ? 1 : 0,
      widget.record.autoTaxis ? 1 : 0,
      widget.record.autoAlgaeRemoved,
      widget.record.autoAlgaeInNet,
      widget.record.autoAlgaeInProcessor,
      
      // coral success/failure
      widget.record.teleopCoralHeight3Success,
      widget.record.teleopCoralHeight3Failure,
      widget.record.autoCoralHeight1Success,
      widget.record.autoCoralHeight1Failure,
      widget.record.autoCoralHeight2Success,
      widget.record.autoCoralHeight2Failure,
      widget.record.autoCoralHeight3Success,
      widget.record.autoCoralHeight3Failure,
      widget.record.autoCoralHeight4Success,
      widget.record.autoCoralHeight4Failure,
      widget.record.teleopCoralHeight4Success,
      widget.record.teleopCoralHeight4Failure,
      widget.record.teleopCoralHeight2Success,
      widget.record.teleopCoralHeight2Failure,
      widget.record.teleopCoralHeight1Success,
      widget.record.teleopCoralHeight1Failure,

      // teleop
      widget.record.teleopCoralRankingPoint ? 1 : 0,
      widget.record.teleopAlgaeRemoved,
      widget.record.teleopAlgaeProcessorAttempts,
      widget.record.teleopAlgaeProcessed,
      widget.record.teleopAlgaeScoredInNet,
      widget.record.teleopCanPickupAlgae ? 1 : 0,
      widget.record.teleopCoralPickupMethod,

      // endgame
      widget.record.endgameReturnedToBarge ? 1 : 0,
      widget.record.endgameCageHang,
      widget.record.endgameBargeRankingPoint ? 1 : 0,

      // other
      widget.record.otherCoOpPoint ? 1 : 0,
      widget.record.otherBreakdown ? 1 : 0,
      widget.record.otherComments,
      
      // auto path
      widget.record.robotPath,
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