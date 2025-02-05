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

  void _processScannedData(String? csvData) {
    if (csvData == null) return;

    try {
      final record = _parseCsvToScoutingRecord(csvData);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Match Info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Match #: ${record.matchNumber}'),
                Text('Team #: ${record.teamNumber}'),
              ],
            ),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  ScoutingRecord _parseCsvToScoutingRecord(String csvData) {
    final rows = RegExp(r'(?:\"([^\"]*)\")|([^",]+)')
      .allMatches(csvData)
      .map((match) => match.group(1) ?? match.group(2) ?? '')
      .toList();
    if (rows.length < 5) {
      throw Exception('Invalid CSV format');
    }

    return ScoutingRecord(
      // Match info
      matchNumber: int.tryParse(rows[0]) ?? 0,
      matchType: rows[1],
      timestamp: rows[2],
      teamNumber: int.tryParse(rows[3]) ?? 0,
      isRedAlliance: rows[4].toLowerCase() == 'true',

      // Auto
      cageType: rows[5],
      coralPreloaded: rows[6].toLowerCase() == 'true',
      taxis: rows[7].toLowerCase() == 'true',
      algaeRemoved: int.tryParse(rows[8]) ?? 0,
      coralPlaced: rows[9],
      rankingPoint: rows[10].toLowerCase() == 'true',
      canPickupCoral: rows[11].toLowerCase() == 'true',
      canPickupAlgae: rows[12].toLowerCase() == 'true',
      autoAlgaeInNet: int.tryParse(rows[13]) ?? 0,
      autoAlgaeInProcessor: int.tryParse(rows[14]) ?? 0,
      coralPickupMethod: rows.length > 26 ? rows[15] : 'None',

      // Teleop
      coralOnReefHeight1: rows.length > 28 ? int.tryParse(rows[16]) ?? 0 : 0,
      coralOnReefHeight2: rows.length > 29 ? int.tryParse(rows[17]) ?? 0 : 0,
      coralOnReefHeight3: rows.length > 30 ? int.tryParse(rows[18]) ?? 0 : 0,
      coralOnReefHeight4: rows.length > 31 ? int.tryParse(rows[19]) ?? 0 : 0,
      feederStation: rows.length > 27 ? rows[20] : 'Unknown',
      algaeScoredInNet: int.tryParse(rows[21]) ?? 0,
      coralRankingPoint: rows[22].toLowerCase() == 'true',
      algaeProcessed: int.tryParse(rows[23]) ?? 0,
      processedAlgaeScored: int.tryParse(rows[24]) ?? 0,
      processorCycles: int.tryParse(rows[25]) ?? 0,
      coOpPoint: rows[26].toLowerCase() == 'true',

      // Endgame
      returnedToBarge: rows[27].toLowerCase() == 'true',
      cageHang: rows[28],
      bargeRankingPoint: rows[29].toLowerCase() == 'true',

      // Other
      breakdown: rows[30].toLowerCase() == 'true',
      comments: rows[31],
    );
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
            onPressed: () {
              controller.toggleTorch();
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          if (barcode.rawValue != null) {
            controller.stop();
            _processScannedData(barcode.rawValue);
          }
        },
      ),
    );
  }
}
