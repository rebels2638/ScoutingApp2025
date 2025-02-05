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
      final record = _parseQrData(csvData);

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

  ScoutingRecord _parseQrData(String data) {
    try {
      final List<List<dynamic>> rows = const CsvToListConverter().convert(data);
      if (rows.isEmpty) throw Exception('Invalid QR code data');
      
      final row = rows[0];
      return ScoutingRecord(
        timestamp: row[0].toString(),
        matchNumber: int.parse(row[1].toString()),
        matchType: row[2].toString(),
        teamNumber: int.parse(row[3].toString()),
        isRedAlliance: row[4].toString() == '1',
        cageType: row[5].toString(),
        coralPreloaded: row[6].toString() == '1',
        taxis: row[7].toString() == '1',
        algaeRemoved: int.parse(row[8].toString()),
        coralPlaced: row[9].toString(),
        rankingPoint: row[10].toString() == '1',
        canPickupCoral: row[11].toString() == '1',
        canPickupAlgae: row[12].toString() == '1',
        algaeScoredInNet: int.parse(row[13].toString()),
        coralRankingPoint: row[14].toString() == '1',
        algaeProcessed: int.parse(row[15].toString()),
        processedAlgaeScored: int.parse(row[16].toString()),
        processorCycles: int.parse(row[17].toString()),
        coOpPoint: row[18].toString() == '1',
        returnedToBarge: row[19].toString() == '1',
        cageHang: row[20].toString(),
        bargeRankingPoint: row[21].toString() == '1',
        breakdown: row[22].toString() == '1',
        comments: row[23].toString(),
        autoAlgaeInNet: int.parse(row[24].toString()),
        autoAlgaeInProcessor: int.parse(row[25].toString()),
        coralPickupMethod: row[26].toString(),
        coralOnReefHeight1: int.parse(row[27].toString()),
        coralOnReefHeight2: int.parse(row[28].toString()),
        coralOnReefHeight3: int.parse(row[29].toString()),
        coralOnReefHeight4: int.parse(row[30].toString()),
        feederStation: row[31].toString(),
        robotPath: row[32].toString().isNotEmpty ? 
          jsonDecode(row[32].toString()) as List<Map<String, dynamic>> : 
          null,
      );
    } catch (e) {
      print('Error parsing QR data: $e');
      throw Exception('Invalid QR code format');
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
