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
      widget.record.timestamp,
      widget.record.matchNumber,
      widget.record.matchType,
      widget.record.teamNumber,
      widget.record.isRedAlliance ? 1 : 0,
      widget.record.cageType,
      widget.record.coralPreloaded ? 1 : 0,
      widget.record.taxis ? 1 : 0,
      widget.record.algaeRemoved,
      widget.record.coralPlaced,
      widget.record.rankingPoint ? 1 : 0,
      widget.record.canPickupCoral ? 1 : 0,
      widget.record.canPickupAlgae ? 1 : 0,
      widget.record.autoAlgaeInNet,
      widget.record.autoAlgaeInProcessor,
      widget.record.coralPickupMethod,
      widget.record.coralOnReefHeight1,
      widget.record.coralOnReefHeight2,
      widget.record.coralOnReefHeight3,
      widget.record.coralOnReefHeight4,
      widget.record.feederStation,
      widget.record.algaeScoredInNet,
      widget.record.coralRankingPoint ? 1 : 0,
      widget.record.algaeProcessed,
      widget.record.processedAlgaeScored,
      widget.record.processorCycles,
      widget.record.coOpPoint ? 1 : 0,
      widget.record.returnedToBarge ? 1 : 0,
      widget.record.cageHang,
      widget.record.bargeRankingPoint ? 1 : 0,
      widget.record.breakdown ? 1 : 0,
      widget.record.comments,
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