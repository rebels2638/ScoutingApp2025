import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'data.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class QrScannerPage extends StatefulWidget {
  @override
  _QrScannerPageState createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  DateTime? _lastScanTime;
  int _qrRateLimit = 1500; // Default value in milliseconds
  static const int qrSuccessIndicatorDuration = 200; // Duration to show green border in milliseconds
  Color _borderColor = Colors.yellow;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadRateLimit();
    
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
      
      // Create a ScoutingRecord from the array data
      final record = ScoutingRecord(
        timestamp: data[0] as String,
        matchNumber: data[1] as int,
        matchType: data[2] as String,
        teamNumber: data[3] as int,
        isRedAlliance: data[4] == 1,
        cageType: data[5] as String,
        coralPreloaded: data[6] == 1,
        taxis: data[7] == 1,
        algaeRemoved: data[8] as int,
        coralPlaced: data[9] as String,
        rankingPoint: data[10] == 1,
        canPickupCoral: data[11] == 1,
        canPickupAlgae: data[12] == 1,
        autoAlgaeInNet: data[13] as int,
        autoAlgaeInProcessor: data[14] as int,
        coralPickupMethod: data[15] as String,
        coralOnReefHeight1: data[16] as int,
        coralOnReefHeight2: data[17] as int,
        coralOnReefHeight3: data[18] as int,
        coralOnReefHeight4: data[19] as int,
        feederStation: data[20] as String,
        algaeScoredInNet: data[21] as int,
        coralRankingPoint: data[22] == 1,
        algaeProcessed: data[23] as int,
        processedAlgaeScored: data[24] as int,
        processorCycles: data[25] as int,
        coOpPoint: data[26] == 1,
        returnedToBarge: data[27] == 1,
        cageHang: data[28] as String,
        bargeRankingPoint: data[29] == 1,
        breakdown: data[30] == 1,
        comments: data[31] as String,
        robotPath: null,
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