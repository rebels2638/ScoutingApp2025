import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'data.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class QrScannerPage extends StatefulWidget {
  @override
  _QrScannerPageState createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  MobileScannerController controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
    // add these settings to prevent flipping
    detectionTimeoutMs: 500,
    returnImage: false,
  );
  bool _isProcessing = false;
  DateTime? _lastScanTime;
  int _qrRateLimit = 1500; // default val (ms)
  static const int qrSuccessIndicatorDuration = 200; // duration to show green border (ms)
  Color _borderColor = Colors.yellow;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadRateLimit();
    
    // lock the screen orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    // Start periodic status check
    _statusCheckTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_lastScanTime != null) {
        final timeSinceLastScan = DateTime.now().difference(_lastScanTime!).inMilliseconds;
        if (timeSinceLastScan >= _qrRateLimit && mounted) {
          setState(() {
            _borderColor = Colors.yellow;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    controller.dispose();
    // reset orientation settings
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _loadRateLimit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _qrRateLimit = prefs.getInt('qr_rate_limit') ?? 1500;
    });
  }

  bool _canScan() {
    if (_lastScanTime == null) return true;
    final timeSinceLastScan = DateTime.now().difference(_lastScanTime!).inMilliseconds;
    return timeSinceLastScan >= _qrRateLimit;
  }

  void _processScannedData(String? rawData) {
    if (rawData == null || _isProcessing || !_canScan()) return;
    
    _lastScanTime = DateTime.now();
    _isProcessing = true;

    // Show success indicator
    setState(() {
      _borderColor = Colors.green;
    });

    // Reset border color after success duration
    Future.delayed(Duration(milliseconds: qrSuccessIndicatorDuration), () {
      if (mounted) {
        setState(() {
          _borderColor = Colors.red; // Will be updated by _canScan() when ready
        });
      }
    });

    try {
      // Parse the JSON array
      final List<dynamic> data = jsonDecode(rawData);
      
      // create ScoutingRecord from array data
      final record = ScoutingRecord(
        timestamp: data[0] as String? ?? '',
        matchNumber: data[1] as int? ?? 0,
        matchType: data[2] as String? ?? 'Qualification',
        teamNumber: data[3] as int? ?? 0,
        isRedAlliance: data[4] == 1,
        cageType: data[5] as String? ?? 'Shallow',
        
        // auto
        autoCoralPreloaded: data[6] == 1,
        autoTaxis: data[7] == 1,
        autoAlgaeRemoved: data[8] as int? ?? 0,
        autoAlgaeInNet: data[9] as int? ?? 0,
        autoAlgaeInProcessor: data[10] as int? ?? 0,
        
        // coral success/failure
        teleopCoralHeight3Success: data[11] as int? ?? 0,
        teleopCoralHeight3Failure: data[12] as int? ?? 0,
        autoCoralHeight1Success: data[13] as int? ?? 0,
        autoCoralHeight1Failure: data[14] as int? ?? 0,
        autoCoralHeight2Success: data[15] as int? ?? 0,
        autoCoralHeight2Failure: data[16] as int? ?? 0,
        autoCoralHeight3Success: data[17] as int? ?? 0,
        autoCoralHeight3Failure: data[18] as int? ?? 0,
        autoCoralHeight4Success: data[19] as int? ?? 0,
        autoCoralHeight4Failure: data[20] as int? ?? 0,
        teleopCoralHeight4Success: data[21] as int? ?? 0,
        teleopCoralHeight4Failure: data[22] as int? ?? 0,
        teleopCoralHeight2Success: data[23] as int? ?? 0,
        teleopCoralHeight2Failure: data[24] as int? ?? 0,
        teleopCoralHeight1Success: data[25] as int? ?? 0,
        teleopCoralHeight1Failure: data[26] as int? ?? 0,
        
        // teleop
        teleopCoralRankingPoint: data[27] == 1,
        teleopAlgaeRemoved: data[28] as int? ?? 0,
        teleopAlgaeProcessorAttempts: data[29] as int? ?? 0,
        teleopAlgaeProcessed: data[30] as int? ?? 0,
        teleopAlgaeScoredInNet: data[31] as int? ?? 0,
        teleopCanPickupAlgae: data[32] == 1,
        teleopCoralPickupMethod: data[33] as String? ?? 'None',
        
        // Endgame
        endgameReturnedToBarge: data[34] == 1,
        endgameCageHang: data[35] as String? ?? 'None',
        endgameBargeRankingPoint: data[36] == 1,
        
        // Other
        otherCoOpPoint: data[37] == 1,
        otherBreakdown: data[38] == 1,
        otherComments: data[39] as String? ?? '',
        
        // robot path
        robotPath: data[40] != null
            ? (data[40] as List<dynamic>)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : null,

        // legacy fields (required by constructor)
        coralPreloaded: data[6] == 1,
        taxis: data[7] == 1,
        algaeRemoved: data[8] as int? ?? 0,
        coralPlaced: 'No',
        rankingPoint: data[27] == 1,
        canPickupCoral: data[32] == 1,
        canPickupAlgae: data[32] == 1,
        algaeScoredInNet: data[31] as int? ?? 0,
        coralRankingPoint: data[27] == 1,
        algaeProcessed: data[30] as int? ?? 0,
        processedAlgaeScored: data[30] as int? ?? 0,
        processorCycles: data[29] as int? ?? 0,
        coOpPoint: data[37] == 1,
        returnedToBarge: data[34] == 1,
        cageHang: data[35] as String? ?? 'None',
        bargeRankingPoint: data[36] == 1,
        breakdown: data[38] == 1,
        comments: data[39] as String? ?? '',
        coralPickupMethod: data[33] as String? ?? 'None',
        feederStation: 'None',
        coralOnReefHeight1: data[25] as int? ?? 0,
        coralOnReefHeight2: data[23] as int? ?? 0,
        coralOnReefHeight3: data[11] as int? ?? 0,
        coralOnReefHeight4: data[21] as int? ?? 0,
      );

      // OLD SCAN POPUP STUFF BELOW
      /*  
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Match Info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Team ${record.teamNumber}'),
                Text('Match ${record.matchNumber}'),
                Text('Type: ${record.matchType}'),
                Text('Alliance: ${record.isRedAlliance ? "Red" : "Blue"}'),
              ],
      */

      // Save the record directly
      DataManager.saveRecord(record).then((_) {
        // Show a brief success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Team ${record.teamNumber} Match ${record.matchNumber} saved'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 100,
              left: 16,
              right: 16,
            ),
          ),
        );

        // OLD SCAN POPUP STUFF BELOW
        /*
        actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await DataManager.saveRecord(record);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Record saved successfully')),
                  );
                },
                child: Text('Save'),
              ),
            ],
          );
        },
      );
      */

        _isProcessing = false;
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $error')),
        );
        _isProcessing = false;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Invalid QR code format')),
      );
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color textColor;
    
    // determine status text and color based on border color
    switch (_borderColor) {
      case Colors.green:
        statusText = "QR Code Scanned";
        textColor = Colors.green;
        break;
      case Colors.red:
        statusText = "Rate Limited";
        textColor = Colors.red;
        break;
      default:
        statusText = "Waiting for QR Code...";
        textColor = Colors.yellow;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processScannedData(barcode.rawValue);
                  break;
                }
              }
            },
            scanWindow: Rect.largest,
            startDelay: true,
            placeholderBuilder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: child,
              );
            },
          ),
          // Animated border overlay
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _borderColor,
                width: 4.0,
              ),
            ),
          ),
          // status text overlay
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.black54,
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}