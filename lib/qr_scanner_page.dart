import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'data.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

class QrScannerPage extends StatefulWidget {
  @override
  _QrScannerPageState createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  MobileScannerController controller = MobileScannerController();

  void _processScannedData(String? rawData) {
    if (rawData == null) return;

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

        // Resume scanning
        controller.start();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $error')),
        );
        controller.start();
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Invalid QR code format')),
      );
      controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              controller.stop();
              _processScannedData(barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}