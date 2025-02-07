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
    try {
      final List<List<dynamic>> rows = const CsvToListConverter(fieldDelimiter: '|').convert(csvData);
      if (rows.isEmpty) throw Exception('Invalid QR code data');

      final row = rows[0];
      return ScoutingRecord(
        timestamp: row[0].toString(),
        matchNumber: int.tryParse(row[1].toString()) ?? 0,
        matchType: row[2].toString(),
        teamNumber: int.tryParse(row[3].toString()) ?? 0,
        isRedAlliance: row[4].toString() == '1',
        cageType: row[5].toString(),
        coralPreloaded: row[6].toString() == '1',
        taxis: row[7].toString() == '1',
        algaeRemoved: int.tryParse(row[8].toString()) ?? 0,
        coralPlaced: row[9].toString(),
        rankingPoint: row[10].toString() == '1',
        canPickupCoral: row[11].toString() == '1',
        canPickupAlgae: row[12].toString() == '1',
        algaeScoredInNet: int.tryParse(row[13].toString()) ?? 0,
        coralRankingPoint: row[14].toString() == '1',
        algaeProcessed: int.tryParse(row[15].toString()) ?? 0,
        processedAlgaeScored: int.tryParse(row[16].toString()) ?? 0,
        processorCycles: int.tryParse(row[17].toString()) ?? 0,
        coOpPoint: row[18].toString() == '1',
        returnedToBarge: row[19].toString() == '1',
        cageHang: row[20].toString(),
        bargeRankingPoint: row[21].toString() == '1',
        breakdown: row[22].toString() == '1',
        comments: row[23].toString(),
        autoAlgaeInNet: int.tryParse(row[24].toString()) ?? 0,
        autoAlgaeInProcessor: int.tryParse(row[25].toString()) ?? 0,
        coralPickupMethod: row[26].toString(),
        coralOnReefHeight1: int.tryParse(row[27].toString()) ?? 0,
        coralOnReefHeight2: int.tryParse(row[28].toString()) ?? 0,
        coralOnReefHeight3: int.tryParse(row[29].toString()) ?? 0,
        coralOnReefHeight4: int.tryParse(row[30].toString()) ?? 0,
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
            }
          }
        },
      ),
    );
  }
}