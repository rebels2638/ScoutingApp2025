import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import 'comparison.dart';
import 'team_analysis.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:csv/csv.dart';
import 'drawing_page.dart' as drawing;
import 'theme/app_theme.dart';
import 'database_helper.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'record_detail.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'qr_scanner_page.dart';
import 'services/ble_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auto_path_photo_page.dart';
import 'visualization_page.dart';
import 'widgets/qr_code_dialog.dart';

class ScoutingRecord {
  final String timestamp;
  final int matchNumber;
  final String matchType;
  final int teamNumber;
  final bool isRedAlliance;

  // Auto
  final bool autoTaxis;
  final bool autoCoralPreloaded;
  final int autoAlgaeRemoved;
  final int autoCoralHeight4Success;
  final int autoCoralHeight4Failure;
  final int autoCoralHeight3Success;
  final int autoCoralHeight3Failure;
  final int autoCoralHeight2Success;
  final int autoCoralHeight2Failure;
  final int autoCoralHeight1Success;
  final int autoCoralHeight1Failure;
  final int autoAlgaeInNet;
  final int autoAlgaeInProcessor;

  // Teleop
  final int teleopCoralHeight4Success;
  final int teleopCoralHeight4Failure;
  final int teleopCoralHeight3Success;
  final int teleopCoralHeight3Failure;
  final int teleopCoralHeight2Success;
  final int teleopCoralHeight2Failure;
  final int teleopCoralHeight1Success;
  final int teleopCoralHeight1Failure;
  final bool teleopCoralRankingPoint;
  final int teleopAlgaeRemoved;
  final int teleopAlgaeProcessorAttempts;
  final int teleopAlgaeProcessed;
  final int teleopAlgaeScoredInNet;
  final bool teleopCanPickupAlgae;
  final String teleopCoralPickupMethod;

  // Endgame
  final bool endgameReturnedToBarge;
  final String endgameCageHang;
  final bool endgameBargeRankingPoint;

  // Other
  final bool otherCoOpPoint;
  final bool otherBreakdown;
  final String otherComments;

  // Legacy fields needed for compatibility
  final String cageType;
  final bool coralPreloaded;
  final bool taxis;
  final int algaeRemoved;
  final String coralPlaced;
  final bool rankingPoint;
  final bool canPickupCoral;
  final bool canPickupAlgae;
  final int algaeScoredInNet;
  final bool coralRankingPoint;
  final int algaeProcessed;
  final int processedAlgaeScored;
  final int processorCycles;
  final bool coOpPoint;
  final bool returnedToBarge;
  final String cageHang;
  final bool bargeRankingPoint;
  final bool breakdown;
  final String comments;
  final String coralPickupMethod;
  final String feederStation;
  final int coralOnReefHeight1;
  final int coralOnReefHeight2;
  final int coralOnReefHeight3;
  final int coralOnReefHeight4;
  final List<Map<String, dynamic>>? robotPath;

  const ScoutingRecord({
    required this.timestamp,
    required this.matchNumber,
    required this.matchType,
    required this.teamNumber,
    required this.isRedAlliance,
    
    // Auto
    required this.autoTaxis,
    required this.autoCoralPreloaded,
    required this.autoAlgaeRemoved,
    required this.autoCoralHeight4Success,
    required this.autoCoralHeight4Failure,
    required this.autoCoralHeight3Success,
    required this.autoCoralHeight3Failure,
    required this.autoCoralHeight2Success,
    required this.autoCoralHeight2Failure,
    required this.autoCoralHeight1Success,
    required this.autoCoralHeight1Failure,
    required this.autoAlgaeInNet,
    required this.autoAlgaeInProcessor,

    // Teleop
    required this.teleopCoralHeight4Success,
    required this.teleopCoralHeight4Failure,
    required this.teleopCoralHeight3Success,
    required this.teleopCoralHeight3Failure,
    required this.teleopCoralHeight2Success,
    required this.teleopCoralHeight2Failure,
    required this.teleopCoralHeight1Success,
    required this.teleopCoralHeight1Failure,
    required this.teleopCoralRankingPoint,
    required this.teleopAlgaeRemoved,
    required this.teleopAlgaeProcessorAttempts,
    required this.teleopAlgaeProcessed,
    required this.teleopAlgaeScoredInNet,
    required this.teleopCanPickupAlgae,
    required this.teleopCoralPickupMethod,

    // Endgame
    required this.endgameReturnedToBarge,
    required this.endgameCageHang,
    required this.endgameBargeRankingPoint,

    // Other
    required this.otherCoOpPoint,
    required this.otherBreakdown,
    required this.otherComments,

    // Legacy fields
    required this.cageType,
    required this.coralPreloaded,
    required this.taxis,
    required this.algaeRemoved,
    required this.coralPlaced,
    required this.rankingPoint,
    required this.canPickupCoral,
    required this.canPickupAlgae,
    required this.algaeScoredInNet,
    required this.coralRankingPoint,
    required this.algaeProcessed,
    required this.processedAlgaeScored,
    required this.processorCycles,
    required this.coOpPoint,
    required this.returnedToBarge,
    required this.cageHang,
    required this.bargeRankingPoint,
    required this.breakdown,
    required this.comments,
    required this.coralPickupMethod,
    required this.feederStation,
    required this.coralOnReefHeight1,
    required this.coralOnReefHeight2,
    required this.coralOnReefHeight3,
    required this.coralOnReefHeight4,
    this.robotPath,
  });

  Map<String, dynamic> toJson() {
    return {
      // Match info
      'timestamp': timestamp,
      'matchNumber': matchNumber,
      'matchType': matchType,
      'teamNumber': teamNumber,
      'isRedAlliance': isRedAlliance,
      
      // Auto
      'autoTaxis': autoTaxis,
      'autoCoralPreloaded': autoCoralPreloaded,
      'autoAlgaeRemoved': autoAlgaeRemoved,
      'autoCoralHeight4Success': autoCoralHeight4Success,
      'autoCoralHeight4Failure': autoCoralHeight4Failure,
      'autoCoralHeight3Success': autoCoralHeight3Success,
      'autoCoralHeight3Failure': autoCoralHeight3Failure,
      'autoCoralHeight2Success': autoCoralHeight2Success,
      'autoCoralHeight2Failure': autoCoralHeight2Failure,
      'autoCoralHeight1Success': autoCoralHeight1Success,
      'autoCoralHeight1Failure': autoCoralHeight1Failure,
      'autoAlgaeInNet': autoAlgaeInNet,
      'autoAlgaeInProcessor': autoAlgaeInProcessor,

      // Teleop
      'teleopCoralHeight4Success': teleopCoralHeight4Success,
      'teleopCoralHeight4Failure': teleopCoralHeight4Failure,
      'teleopCoralHeight3Success': teleopCoralHeight3Success,
      'teleopCoralHeight3Failure': teleopCoralHeight3Failure,
      'teleopCoralHeight2Success': teleopCoralHeight2Success,
      'teleopCoralHeight2Failure': teleopCoralHeight2Failure,
      'teleopCoralHeight1Success': teleopCoralHeight1Success,
      'teleopCoralHeight1Failure': teleopCoralHeight1Failure,
      'teleopCoralRankingPoint': teleopCoralRankingPoint,
      'teleopAlgaeRemoved': teleopAlgaeRemoved,
      'teleopAlgaeProcessorAttempts': teleopAlgaeProcessorAttempts,
      'teleopAlgaeProcessed': teleopAlgaeProcessed,
      'teleopAlgaeScoredInNet': teleopAlgaeScoredInNet,
      'teleopCanPickupAlgae': teleopCanPickupAlgae,
      'teleopCoralPickupMethod': teleopCoralPickupMethod,

      // Endgame
      'endgameReturnedToBarge': endgameReturnedToBarge,
      'endgameCageHang': endgameCageHang,
      'endgameBargeRankingPoint': endgameBargeRankingPoint,

      // Other
      'otherCoOpPoint': otherCoOpPoint,
      'otherBreakdown': otherBreakdown,
      'otherComments': otherComments,

      // Legacy fields
      'cageType': cageType,
      'coralPreloaded': coralPreloaded,
      'taxis': taxis,
      'algaeRemoved': algaeRemoved,
      'coralPlaced': coralPlaced,
      'rankingPoint': rankingPoint,
      'canPickupCoral': canPickupCoral,
      'canPickupAlgae': canPickupAlgae,
      'algaeScoredInNet': algaeScoredInNet,
      'coralRankingPoint': coralRankingPoint,
      'algaeProcessed': algaeProcessed,
      'processedAlgaeScored': processedAlgaeScored,
      'processorCycles': processorCycles,
      'coOpPoint': coOpPoint,
      'returnedToBarge': returnedToBarge,
      'cageHang': cageHang,
      'bargeRankingPoint': bargeRankingPoint,
      'breakdown': breakdown,
      'comments': comments,
      'coralPickupMethod': coralPickupMethod,
      'feederStation': feederStation,
      'coralOnReefHeight1': coralOnReefHeight1,
      'coralOnReefHeight2': coralOnReefHeight2,
      'coralOnReefHeight3': coralOnReefHeight3,
      'coralOnReefHeight4': coralOnReefHeight4,
      'robotPath': robotPath,
    };
  }

  factory ScoutingRecord.fromJson(Map<String, dynamic> json) {
    return ScoutingRecord(
      timestamp: json['timestamp'] as String? ?? '',
      matchNumber: json['matchNumber'] as int? ?? 0,
      matchType: json['matchType'] as String? ?? 'Qualification',
      teamNumber: json['teamNumber'] as int? ?? 0,
      isRedAlliance: json['isRedAlliance'] as bool? ?? false,
      
      // Auto
      autoTaxis: json['autoTaxis'] as bool? ?? false,
      autoCoralPreloaded: json['autoCoralPreloaded'] as bool? ?? false,
      autoAlgaeRemoved: json['autoAlgaeRemoved'] as int? ?? 0,
      autoCoralHeight4Success: json['autoCoralHeight4Success'] as int? ?? 0,
      autoCoralHeight4Failure: json['autoCoralHeight4Failure'] as int? ?? 0,
      autoCoralHeight3Success: json['autoCoralHeight3Success'] as int? ?? 0,
      autoCoralHeight3Failure: json['autoCoralHeight3Failure'] as int? ?? 0,
      autoCoralHeight2Success: json['autoCoralHeight2Success'] as int? ?? 0,
      autoCoralHeight2Failure: json['autoCoralHeight2Failure'] as int? ?? 0,
      autoCoralHeight1Success: json['autoCoralHeight1Success'] as int? ?? 0,
      autoCoralHeight1Failure: json['autoCoralHeight1Failure'] as int? ?? 0,
      autoAlgaeInNet: json['autoAlgaeInNet'] as int? ?? 0,
      autoAlgaeInProcessor: json['autoAlgaeInProcessor'] as int? ?? 0,

      // Teleop
      teleopCoralHeight4Success: json['teleopCoralHeight4Success'] as int? ?? 0,
      teleopCoralHeight4Failure: json['teleopCoralHeight4Failure'] as int? ?? 0,
      teleopCoralHeight3Success: json['teleopCoralHeight3Success'] as int? ?? 0,
      teleopCoralHeight3Failure: json['teleopCoralHeight3Failure'] as int? ?? 0,
      teleopCoralHeight2Success: json['teleopCoralHeight2Success'] as int? ?? 0,
      teleopCoralHeight2Failure: json['teleopCoralHeight2Failure'] as int? ?? 0,
      teleopCoralHeight1Success: json['teleopCoralHeight1Success'] as int? ?? 0,
      teleopCoralHeight1Failure: json['teleopCoralHeight1Failure'] as int? ?? 0,
      teleopCoralRankingPoint: json['teleopCoralRankingPoint'] as bool? ?? false,
      teleopAlgaeRemoved: json['teleopAlgaeRemoved'] as int? ?? 0,
      teleopAlgaeProcessorAttempts: json['teleopAlgaeProcessorAttempts'] as int? ?? 0,
      teleopAlgaeProcessed: json['teleopAlgaeProcessed'] as int? ?? 0,
      teleopAlgaeScoredInNet: json['teleopAlgaeScoredInNet'] as int? ?? 0,
      teleopCanPickupAlgae: json['teleopCanPickupAlgae'] as bool? ?? false,
      teleopCoralPickupMethod: json['teleopCoralPickupMethod'] as String? ?? 'None',

      // Endgame
      endgameReturnedToBarge: json['endgameReturnedToBarge'] as bool? ?? false,
      endgameCageHang: json['endgameCageHang'] as String? ?? 'None',
      endgameBargeRankingPoint: json['endgameBargeRankingPoint'] as bool? ?? false,

      // Other
      otherCoOpPoint: json['otherCoOpPoint'] as bool? ?? false,
      otherBreakdown: json['otherBreakdown'] as bool? ?? false,
      otherComments: json['otherComments'] as String? ?? '',

      // Legacy fields
      cageType: json['cageType'] as String? ?? 'Shallow',
      coralPreloaded: json['coralPreloaded'] as bool? ?? false,
      taxis: json['taxis'] as bool? ?? false,
      algaeRemoved: json['algaeRemoved'] as int? ?? 0,
      coralPlaced: json['coralPlaced'] as String? ?? 'No',
      rankingPoint: json['rankingPoint'] as bool? ?? false,
      canPickupCoral: json['canPickupCoral'] as bool? ?? false,
      canPickupAlgae: json['canPickupAlgae'] as bool? ?? false,
      algaeScoredInNet: json['algaeScoredInNet'] as int? ?? 0,
      coralRankingPoint: json['coralRankingPoint'] as bool? ?? false,
      algaeProcessed: json['algaeProcessed'] as int? ?? 0,
      processedAlgaeScored: json['processedAlgaeScored'] as int? ?? 0,
      processorCycles: json['processorCycles'] as int? ?? 0,
      coOpPoint: json['coOpPoint'] as bool? ?? false,
      returnedToBarge: json['returnedToBarge'] as bool? ?? false,
      cageHang: json['cageHang'] as String? ?? 'None',
      bargeRankingPoint: json['bargeRankingPoint'] as bool? ?? false,
      breakdown: json['breakdown'] as bool? ?? false,
      comments: json['comments'] as String? ?? '',
      coralPickupMethod: json['coralPickupMethod'] as String? ?? 'None',
      feederStation: json['feederStation'] as String? ?? 'None',
      coralOnReefHeight1: json['coralOnReefHeight1'] as int? ?? 0,
      coralOnReefHeight2: json['coralOnReefHeight2'] as int? ?? 0,
      coralOnReefHeight3: json['coralOnReefHeight3'] as int? ?? 0,
      coralOnReefHeight4: json['coralOnReefHeight4'] as int? ?? 0,
      robotPath: json['robotPath'] != null
          ? (json['robotPath'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toCompressedJson() {
    return {
      'ts': timestamp,
      'mn': matchNumber,
      'mt': matchType,
      'tn': teamNumber,
      'ra': isRedAlliance ? 1 : 0,
      
      // Auto
      'tx': autoTaxis ? 1 : 0,
      'cp': autoCoralPreloaded ? 1 : 0,
      'ar': autoAlgaeRemoved,
      'ch4s': autoCoralHeight4Success,
      'ch4f': autoCoralHeight4Failure,
      'ch3s': autoCoralHeight3Success,
      'ch3f': autoCoralHeight3Failure,
      'ch2s': autoCoralHeight2Success,
      'ch2f': autoCoralHeight2Failure,
      'ch1s': autoCoralHeight1Success,
      'ch1f': autoCoralHeight1Failure,
      'aan': autoAlgaeInNet,
      'aap': autoAlgaeInProcessor,

      // Teleop
      'tch4s': teleopCoralHeight4Success,
      'tch4f': teleopCoralHeight4Failure,
      'tch3s': teleopCoralHeight3Success,
      'tch3f': teleopCoralHeight3Failure,
      'tch2s': teleopCoralHeight2Success,
      'tch2f': teleopCoralHeight2Failure,
      'tch1s': teleopCoralHeight1Success,
      'tch1f': teleopCoralHeight1Failure,
      'crp': teleopCoralRankingPoint ? 1 : 0,
      'tar': teleopAlgaeRemoved,
      'tap': teleopAlgaeProcessorAttempts,
      'tapr': teleopAlgaeProcessed,
      'tasn': teleopAlgaeScoredInNet,
      'tcpa': teleopCanPickupAlgae ? 1 : 0,
      'tcpm': teleopCoralPickupMethod,

      // Endgame
      'rtb': endgameReturnedToBarge ? 1 : 0,
      'ch': endgameCageHang,
      'brp': endgameBargeRankingPoint ? 1 : 0,

      // Other
      'cop': otherCoOpPoint ? 1 : 0,
      'bd': otherBreakdown ? 1 : 0,
      'cm': otherComments,

      // Robot path
      'rp': robotPath?.map((line) {
        return {
          'p': (line['points'] as List).map((p) => {
            'x': (p['x'] as num).toDouble(),
            'y': (p['y'] as num).toDouble(),
          }).toList(),
          'c': line['color'],
          'w': line['strokeWidth'],
          'i': line['imagePath'],
        };
      }).toList(),
    };
  }

  factory ScoutingRecord.fromCompressedJson(Map<String, dynamic> json) {
    return ScoutingRecord(
      timestamp: json['ts'] as String? ?? '',
      matchNumber: json['mn'] as int? ?? 0,
      matchType: json['mt'] as String? ?? 'Qualification',
      teamNumber: json['tn'] as int? ?? 0,
      isRedAlliance: json['ra'] == 1,
      
      // Auto
      autoTaxis: json['tx'] == 1,
      autoCoralPreloaded: json['cp'] == 1,
      autoAlgaeRemoved: json['ar'] as int? ?? 0,
      autoCoralHeight4Success: json['ch4s'] as int? ?? 0,
      autoCoralHeight4Failure: json['ch4f'] as int? ?? 0,
      autoCoralHeight3Success: json['ch3s'] as int? ?? 0,
      autoCoralHeight3Failure: json['ch3f'] as int? ?? 0,
      autoCoralHeight2Success: json['ch2s'] as int? ?? 0,
      autoCoralHeight2Failure: json['ch2f'] as int? ?? 0,
      autoCoralHeight1Success: json['ch1s'] as int? ?? 0,
      autoCoralHeight1Failure: json['ch1f'] as int? ?? 0,
      autoAlgaeInNet: json['aan'] as int? ?? 0,
      autoAlgaeInProcessor: json['aap'] as int? ?? 0,

      // Teleop
      teleopCoralHeight4Success: json['tch4s'] as int? ?? 0,
      teleopCoralHeight4Failure: json['tch4f'] as int? ?? 0,
      teleopCoralHeight3Success: json['tch3s'] as int? ?? 0,
      teleopCoralHeight3Failure: json['tch3f'] as int? ?? 0,
      teleopCoralHeight2Success: json['tch2s'] as int? ?? 0,
      teleopCoralHeight2Failure: json['tch2f'] as int? ?? 0,
      teleopCoralHeight1Success: json['tch1s'] as int? ?? 0,
      teleopCoralHeight1Failure: json['tch1f'] as int? ?? 0,
      teleopCoralRankingPoint: json['crp'] == 1,
      teleopAlgaeRemoved: json['tar'] as int? ?? 0,
      teleopAlgaeProcessorAttempts: json['tap'] as int? ?? 0,
      teleopAlgaeProcessed: json['tapr'] as int? ?? 0,
      teleopAlgaeScoredInNet: json['tasn'] as int? ?? 0,
      teleopCanPickupAlgae: json['tcpa'] == 1,
      teleopCoralPickupMethod: json['tcpm'] as String? ?? 'None',

      // Endgame
      endgameReturnedToBarge: json['rtb'] == 1,
      endgameCageHang: json['ch'] as String? ?? 'None',
      endgameBargeRankingPoint: json['brp'] == 1,

      // Other
      otherCoOpPoint: json['cop'] == 1,
      otherBreakdown: json['bd'] == 1,
      otherComments: json['cm'] as String? ?? '',

      // Legacy fields
      cageType: 'Shallow',
      coralPreloaded: json['cp'] == 1,
      taxis: json['tx'] == 1,
      algaeRemoved: json['ar'] as int? ?? 0,
      coralPlaced: 'No',
      rankingPoint: json['crp'] == 1,
      canPickupCoral: json['tcpa'] == 1,
      canPickupAlgae: json['tcpa'] == 1,
      algaeScoredInNet: json['tasn'] as int? ?? 0,
      coralRankingPoint: json['crp'] == 1,
      algaeProcessed: json['tapr'] as int? ?? 0,
      processedAlgaeScored: json['tapr'] as int? ?? 0,
      processorCycles: json['tap'] as int? ?? 0,
      coOpPoint: json['cop'] == 1,
      returnedToBarge: json['rtb'] == 1,
      cageHang: json['ch'] as String? ?? 'None',
      bargeRankingPoint: json['brp'] == 1,
      breakdown: json['bd'] == 1,
      comments: json['cm'] as String? ?? '',
      coralPickupMethod: json['tcpm'] as String? ?? 'None',
      feederStation: 'None',
      coralOnReefHeight1: json['tch1s'] as int? ?? 0,
      coralOnReefHeight2: json['tch2s'] as int? ?? 0,
      coralOnReefHeight3: json['tch3s'] as int? ?? 0,
      coralOnReefHeight4: json['tch4s'] as int? ?? 0,
      robotPath: json['rp'] != null
          ? (json['rp'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : null,
    );
  }

  List<dynamic> toCsvRow() {
    String robotPathStr = '';
    if (robotPath != null && robotPath!.isNotEmpty) {
      try {
        robotPathStr = jsonEncode(robotPath);
      } catch (e) {
        print('Error encoding robotPath: $e');
      }
    }

    return [
      // Match info
      matchNumber,
      matchType,
      timestamp,
      teamNumber,
      isRedAlliance ? 1 : 0,
      
      // Auto
      autoTaxis ? 1 : 0,
      autoCoralPreloaded ? 1 : 0,
      autoAlgaeRemoved,
      autoCoralHeight4Success,
      autoCoralHeight4Failure,
      autoCoralHeight3Success,
      autoCoralHeight3Failure,
      autoCoralHeight2Success,
      autoCoralHeight2Failure,
      autoCoralHeight1Success,
      autoCoralHeight1Failure,
      autoAlgaeInNet,
      autoAlgaeInProcessor,

      // Teleop
      teleopCoralHeight4Success,
      teleopCoralHeight4Failure,
      teleopCoralHeight3Success,
      teleopCoralHeight3Failure,
      teleopCoralHeight2Success,
      teleopCoralHeight2Failure,
      teleopCoralHeight1Success,
      teleopCoralHeight1Failure,
      teleopCoralRankingPoint ? 1 : 0,
      teleopAlgaeRemoved,
      teleopAlgaeProcessorAttempts,
      teleopAlgaeProcessed,
      teleopAlgaeScoredInNet,
      teleopCanPickupAlgae ? 1 : 0,
      teleopCoralPickupMethod,

      // Endgame
      endgameReturnedToBarge ? 1 : 0,
      endgameCageHang,
      endgameBargeRankingPoint ? 1 : 0,

      // Other
      otherCoOpPoint ? 1 : 0,
      otherBreakdown ? 1 : 0,
      otherComments.replaceAll('|', '\\|'),
      robotPathStr,
    ];
  }

  static List<String> getCsvHeaders() {
    return [
      // Match info
      'Match Number',
      'Match Type',
      'Timestamp',
      'Team Number',
      'Red Alliance',
      
      // Auto
      'Auto Taxis',
      'Auto Coral Preloaded',
      'Auto Algae Removed',
      'Auto Coral Height 4 Success',
      'Auto Coral Height 4 Failure',
      'Auto Coral Height 3 Success',
      'Auto Coral Height 3 Failure',
      'Auto Coral Height 2 Success',
      'Auto Coral Height 2 Failure',
      'Auto Coral Height 1 Success',
      'Auto Coral Height 1 Failure',
      'Auto Algae in Net',
      'Auto Algae in Processor',

      // Teleop
      'Teleop Coral Height 4 Success',
      'Teleop Coral Height 4 Failure',
      'Teleop Coral Height 3 Success',
      'Teleop Coral Height 3 Failure',
      'Teleop Coral Height 2 Success',
      'Teleop Coral Height 2 Failure',
      'Teleop Coral Height 1 Success',
      'Teleop Coral Height 1 Failure',
      'Teleop Coral Ranking Point',
      'Teleop Algae Removed',
      'Teleop Algae Processor Attempts',
      'Teleop Algae Processed',
      'Teleop Algae Scored in Net',
      'Teleop Can Pickup Algae',
      'Teleop Coral Pickup Method',

      // Endgame
      'Endgame Returned to Barge',
      'Endgame Cage Hang',
      'Endgame Barge Ranking Point',

      // Other
      'Other Co-Op Point',
      'Other Breakdown',
      'Other Comments',
      'Robot Path',
    ];
  }

  factory ScoutingRecord.fromCsvRow(List<dynamic> row) {
    List<Map<String, dynamic>>? pathData;
    if (row[32].toString().isNotEmpty) {
      try {
        String robotPathStr = row[32].toString().replaceAll('\\|', '|');
        final decoded = jsonDecode(robotPathStr);
        if (decoded is List) {
          pathData = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      } catch (e) {
        print('Error decoding robotPath: $e');
      }
    }

    return ScoutingRecord(
      // Match info
      matchNumber: int.parse(row[0].toString()),
      matchType: row[1].toString(),
      timestamp: row[2].toString(),
      teamNumber: int.parse(row[3].toString()),
      isRedAlliance: row[4].toString() == '1',
      
      // Auto
      autoTaxis: row[5].toString() == '1',
      autoCoralPreloaded: row[6].toString() == '1',
      autoAlgaeRemoved: int.parse(row[7].toString()),
      autoCoralHeight4Success: int.parse(row[8].toString()),
      autoCoralHeight4Failure: int.parse(row[9].toString()),
      autoCoralHeight3Success: int.parse(row[10].toString()),
      autoCoralHeight3Failure: int.parse(row[11].toString()),
      autoCoralHeight2Success: int.parse(row[12].toString()),
      autoCoralHeight2Failure: int.parse(row[13].toString()),
      autoCoralHeight1Success: int.parse(row[14].toString()),
      autoCoralHeight1Failure: int.parse(row[15].toString()),
      autoAlgaeInNet: int.parse(row[16].toString()),
      autoAlgaeInProcessor: int.parse(row[17].toString()),
      
      // Teleop
      teleopCoralHeight4Success: int.parse(row[18].toString()),
      teleopCoralHeight4Failure: int.parse(row[19].toString()),
      teleopCoralHeight3Success: int.parse(row[20].toString()),
      teleopCoralHeight3Failure: int.parse(row[21].toString()),
      teleopCoralHeight2Success: int.parse(row[22].toString()),
      teleopCoralHeight2Failure: int.parse(row[23].toString()),
      teleopCoralHeight1Success: int.parse(row[24].toString()),
      teleopCoralHeight1Failure: int.parse(row[25].toString()),
      teleopCoralRankingPoint: row[26].toString() == '1',
      teleopAlgaeRemoved: int.parse(row[27].toString()),
      teleopAlgaeProcessorAttempts: int.parse(row[28].toString()),
      teleopAlgaeProcessed: int.parse(row[29].toString()),
      teleopAlgaeScoredInNet: int.parse(row[30].toString()),
      teleopCanPickupAlgae: row[31].toString() == '1',
      teleopCoralPickupMethod: row[32].toString(),
      
      // Endgame
      endgameReturnedToBarge: row[33].toString() == '1',
      endgameCageHang: row[34].toString(),
      endgameBargeRankingPoint: row[35].toString() == '1',
      
      // Other
      otherCoOpPoint: row[36].toString() == '1',
      otherBreakdown: row[37].toString() == '1',
      otherComments: row[38].toString().replaceAll('\\|', '|'),
      robotPath: pathData,
      cageType: 'Shallow',
      coralPreloaded: false,
      taxis: false,
      algaeRemoved: 0,
      coralPlaced: 'No',
      rankingPoint: false,
      canPickupCoral: false,
      canPickupAlgae: false,
      algaeScoredInNet: 0,
      coralRankingPoint: false,
      algaeProcessed: 0,
      processedAlgaeScored: 0,
      processorCycles: 0,
      coOpPoint: false,
      returnedToBarge: false,
      cageHang: 'None',
      bargeRankingPoint: false,
      breakdown: false,
      comments: '',
      coralPickupMethod: 'None',
      feederStation: 'None',
      coralOnReefHeight1: 0,
      coralOnReefHeight2: 0,
      coralOnReefHeight3: 0,
      coralOnReefHeight4: 0,
    );
  }
}

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  List<ScoutingRecord> _records = [];
  
  static Future<void> saveRecord(ScoutingRecord record) async {
    try {
      final records = await DatabaseHelper.instance.getAllRecords();
      records.add(record);
      await DatabaseHelper.instance.saveRecords(records);
    } catch (e) {
      print('Error saving record: $e');
      throw e;
    }
  }

  static Future<List<ScoutingRecord>> getRecords() async {
    try {
      return await DatabaseHelper.instance.getAllRecords();
    } catch (e) {
      print('Error getting records: $e');
      return [];
    }
  }

  static Future<void> deleteRecord(int index) async {
    try {
      final records = await DatabaseHelper.instance.getAllRecords();
      records.removeAt(index);
      await DatabaseHelper.instance.saveRecords(records);
    } catch (e) {
      print('Error deleting record: $e');
      throw e;
    }
  }

  static Future<void> deleteAllRecords() async {
    try {
      await DatabaseHelper.instance.deleteAllRecords();
    } catch (e) {
      print('Error deleting all records: $e');
      throw e;
    }
  }

  // Instance methods
  Future<void> loadRecords() async {
    _records = await DatabaseHelper.instance.getAllRecords();
  }

  List<ScoutingRecord> getRecordsForTeams(Set<int> teamNumbers) {
    if (teamNumbers.isEmpty) return _records;
    return _records.where((r) => teamNumbers.contains(r.teamNumber)).toList();
  }

  List<int> getAllTeamNumbers() {
    return _records.map((r) => r.teamNumber).toSet().toList()..sort();
  }

  // Keep existing statistics and history methods
  Map<String, dynamic> getTeamStats(int teamNumber) {
    final teamRecords = _records.where((r) => r.teamNumber == teamNumber).toList();
    if (teamRecords.isEmpty) return {};

    return {
      'matches': teamRecords.length,
      'avgAutoAlgae': _average(teamRecords.map((r) => r.autoAlgaeRemoved)),
      'avgTeleopAlgae': _average(teamRecords.map((r) => r.teleopAlgaeScoredInNet)),
      'avgProcessed': _average(teamRecords.map((r) => r.teleopAlgaeProcessed)),
      'avgCycles': _average(teamRecords.map((r) => r.teleopAlgaeProcessorAttempts)),
      'taxisSuccess': _percentSuccess(teamRecords.map((r) => r.autoTaxis)),
      'hangSuccess': _percentSuccess(teamRecords.map((r) => r.endgameCageHang != 'None')),
      'breakdowns': teamRecords.where((r) => r.otherBreakdown).length,
    };
  }

  double _average(Iterable<num> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _percentSuccess(Iterable<bool> values) {
    if (values.isEmpty) return 0;
    return values.where((v) => v).length / values.length * 100;
  }

  List<Map<String, dynamic>> getTeamMatchHistory(int teamNumber) {
    return _records
        .where((r) => r.teamNumber == teamNumber)
        .map((r) => {
              'matchNumber': r.matchNumber,
              'matchType': r.matchType,
              'autoAlgae': r.autoAlgaeRemoved,
              'teleopAlgae': r.teleopAlgaeScoredInNet,
              'processed': r.teleopAlgaeProcessed,
              'hang': r.endgameCageHang,
              'breakdown': r.otherBreakdown,
            })
        .toList();
  }
}

class DataPage extends StatefulWidget {
  const DataPage({Key? key}) : super(key: key);

  @override
  DataPageState createState() => DataPageState();
}

class DataPageState extends State<DataPage> {
  List<ScoutingRecord> _records = [];
  Set<int> selectedRecords = {};
  String _searchQuery = '';
  bool _isSelectionMode = false;
  bool _isLoading = false;
  bool _isScoutingLeader = false;
  bool _refreshButtonEnabled = false;

  // add getter for records
  List<ScoutingRecord> get records => _records;

  @override
  void initState() {
    super.initState();
    loadRecords();
    _loadScoutingLeaderStatus();
    _loadRefreshButtonSetting();
  }

  Future<void> _loadRefreshButtonSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshButtonEnabled = prefs.getBool('refresh_button_enabled') ?? false;
    });
  }

  Future<void> loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await DatabaseHelper.instance.getAllRecords();
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading records: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadScoutingLeaderStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isScoutingLeader = prefs.getBool('scouting_leader_enabled') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          _buildActionBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty 
                ? _buildEmptyState()
                : _buildRecordsList(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSearchAndFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.all(8),
      color: isDark 
          ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by team number...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark
                          ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                          : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.surface,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            if (_refreshButtonEnabled) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh data',
                onPressed: () {
                  loadRecords();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Records refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    if (!_isSelectionMode && selectedRecords.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Text(
            '${selectedRecords.length} selected',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (selectedRecords.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare),
              tooltip: 'Compare selected',
              onPressed: () {
                final selectedList = _records
                    .asMap()
                    .entries
                    .where((e) => selectedRecords.contains(e.key))
                    .map((e) => e.value)
                    .toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComparisonPage(records: selectedList),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete selected',
            onPressed: () => _showDeleteConfirmation(context),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Clear selection',
            onPressed: () {
              setState(() {
                selectedRecords.clear();
                _isSelectionMode = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    final filteredRecords = _records.where((record) {
      if (_searchQuery.isEmpty) return true;
      // Only filter by team number
      return record.teamNumber.toString().contains(_searchQuery);
    }).toList();

    // Reverse the list so newer entries appear at the top
    final reversedRecords = filteredRecords.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: reversedRecords.length,
      itemBuilder: (context, index) {
        final record = reversedRecords[index];
        return _buildRecordCard(record, index);
      },
    );
  }

  Widget _buildRecordCard(ScoutingRecord record, int index) {
    final isSelected = selectedRecords.contains(index);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected 
          ? (isDark 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.primaryContainer)
          : isDark 
              ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
              : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? (isDark
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.5))
              : isDark
                  ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                  : Colors.transparent,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                selectedRecords.remove(index);
                if (selectedRecords.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                selectedRecords.add(index);
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordDetailPage(record: record),
              ),
            );
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            if (isSelected) {
              selectedRecords.remove(index);
            } else {
              selectedRecords.add(index);
            }
          });
        },
        leading: _isSelectionMode 
            ? Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDark
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.2))
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? (isDark
                            ? Theme.of(context).colorScheme.primary
                            : Colors.blue)
                        : Colors.grey.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected 
                      ? (isDark
                          ? Theme.of(context).colorScheme.primary
                          : Colors.blue)
                      : Colors.grey.withOpacity(0.7),
                ),
              )
            : null,
        title: Row(
          children: [
            Text(
              'Team ${record.teamNumber}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected && isDark
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: record.isRedAlliance 
                    ? AppColors.redAlliance.withOpacity(isDark ? 0.3 : 0.1)
                    : AppColors.blueAlliance.withOpacity(isDark ? 0.3 : 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                record.isRedAlliance ? 'Red' : 'Blue',
                style: TextStyle(
                  color: record.isRedAlliance 
                      ? AppColors.redAlliance
                      : AppColors.blueAlliance,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${record.timestamp} Match ${record.matchNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            if (record.otherComments.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                record.otherComments,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showRecordOptions(context, record, index),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No scouting records yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start scouting matches to see them here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner),
          label: 'Scan QR Code',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QrScannerPage()),
            );
            // refresh match data records when qr code scanner is closed
            loadRecords();
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.file_upload),
          label: 'Import Data',
          onTap: _importData,
        ),
        SpeedDialChild(
          child: const Icon(Icons.file_download),
          label: 'Export Data',
          onTap: _exportData,
        ),
        /*
        SpeedDialChild(
          child: const Icon(Icons.analytics),
          label: 'Team Analysis',
          onTap: () => _showTeamAnalysis(context),
        ),
        */
        /*
        SpeedDialChild(
          child: const Icon(Icons.bar_chart),
          label: 'Visualizations',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisualizationPage(records: _records),
            ),
          ),
        ),
        */
        SpeedDialChild(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          child: const Icon(Icons.delete_forever),
          label: 'Delete All Data',
          onTap: () => _showDeleteAllConfirmation(context),
        ),
      ],
    );
  }

  void _showRecordOptions(BuildContext context, ScoutingRecord record, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecordDetailPage(record: record),
                  ),
                );
              },
            ),
            if (record.robotPath != null)
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('View Auto Path'),
                onTap: () {
                  Navigator.pop(context);
                  // Find the first path with an image
                  final imagePath = record.robotPath?.firstWhere(
                    (path) => path['imagePath'] != null && File(path['imagePath'] as String).existsSync(),
                    orElse: () => {'imagePath': null},
                  )['imagePath'] as String?;
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => drawing.DrawingPage(
                        isRedAlliance: record.isRedAlliance,
                        initialDrawing: record.robotPath,
                        readOnly: true,
                        imagePath: imagePath,
                      ),
                    ),
                  );
                },
              ),
            if (_isScoutingLeader && (record.robotPath == null || record.robotPath!.isEmpty))
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Auto Path Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AutoPathPhotoPage(
                        isRedAlliance: record.isRedAlliance,
                      ),
                    ),
                  );
                  
                  if (result != null && mounted) {
                    // Get existing path data if any
                    List<Map<String, dynamic>> updatedPath = [];
                    if (record.robotPath != null) {
                      updatedPath.addAll(record.robotPath!);
                    }
                    // Add new path data
                    updatedPath.addAll(result as List<Map<String, dynamic>>);
                    
                    // Create updated record with new path
                    final updatedRecord = ScoutingRecord(
                      timestamp: record.timestamp,
                      matchNumber: record.matchNumber,
                      matchType: record.matchType,
                      teamNumber: record.teamNumber,
                      isRedAlliance: record.isRedAlliance,
                      cageType: record.cageType,
                      coralPreloaded: record.coralPreloaded,
                      taxis: record.taxis,
                      algaeRemoved: record.algaeRemoved,
                      coralPlaced: record.coralPlaced,
                      rankingPoint: record.rankingPoint,
                      canPickupCoral: record.canPickupCoral,
                      canPickupAlgae: record.canPickupAlgae,
                      algaeScoredInNet: record.algaeScoredInNet,
                      coralRankingPoint: record.coralRankingPoint,
                      algaeProcessed: record.algaeProcessed,
                      processedAlgaeScored: record.processedAlgaeScored,
                      processorCycles: record.processorCycles,
                      coOpPoint: record.coOpPoint,
                      returnedToBarge: record.returnedToBarge,
                      cageHang: record.cageHang,
                      bargeRankingPoint: record.bargeRankingPoint,
                      breakdown: record.breakdown,
                      comments: record.comments,
                      autoAlgaeInNet: record.autoAlgaeInNet,
                      autoAlgaeInProcessor: record.autoAlgaeInProcessor,
                      coralPickupMethod: record.coralPickupMethod,
                      coralOnReefHeight1: record.coralOnReefHeight1,
                      coralOnReefHeight2: record.coralOnReefHeight2,
                      coralOnReefHeight3: record.coralOnReefHeight3,
                      coralOnReefHeight4: record.coralOnReefHeight4,
                      feederStation: record.feederStation,
                      robotPath: updatedPath,
                      autoTaxis: record.autoTaxis,
                      autoCoralPreloaded: record.autoCoralPreloaded,
                      autoAlgaeRemoved: record.autoAlgaeRemoved,
                      autoCoralHeight4Success: record.autoCoralHeight4Success,
                      autoCoralHeight4Failure: record.autoCoralHeight4Failure,
                      autoCoralHeight3Success: record.autoCoralHeight3Success,
                      autoCoralHeight3Failure: record.autoCoralHeight3Failure,
                      autoCoralHeight2Success: record.autoCoralHeight2Success,
                      autoCoralHeight2Failure: record.autoCoralHeight2Failure,
                      autoCoralHeight1Success: record.autoCoralHeight1Success,
                      autoCoralHeight1Failure: record.autoCoralHeight1Failure,
                      teleopCoralHeight4Success: record.teleopCoralHeight4Success,
                      teleopCoralHeight4Failure: record.teleopCoralHeight4Failure,
                      teleopCoralHeight3Success: record.teleopCoralHeight3Success,
                      teleopCoralHeight3Failure: record.teleopCoralHeight3Failure,
                      teleopCoralHeight2Success: record.teleopCoralHeight2Success,
                      teleopCoralHeight2Failure: record.teleopCoralHeight2Failure,
                      teleopCoralHeight1Success: record.teleopCoralHeight1Success,
                      teleopCoralHeight1Failure: record.teleopCoralHeight1Failure,
                      teleopCoralRankingPoint: record.teleopCoralRankingPoint,
                      teleopAlgaeRemoved: record.teleopAlgaeRemoved,
                      teleopAlgaeProcessorAttempts: record.teleopAlgaeProcessorAttempts,
                      teleopAlgaeProcessed: record.teleopAlgaeProcessed,
                      teleopAlgaeScoredInNet: record.teleopAlgaeScoredInNet,
                      teleopCanPickupAlgae: record.teleopCanPickupAlgae,
                      teleopCoralPickupMethod: record.teleopCoralPickupMethod,
                      endgameReturnedToBarge: record.endgameReturnedToBarge,
                      endgameCageHang: record.endgameCageHang,
                      endgameBargeRankingPoint: record.endgameBargeRankingPoint,
                      otherCoOpPoint: record.otherCoOpPoint,
                      otherBreakdown: record.otherBreakdown,
                      otherComments: record.otherComments,
                    );

                    // Update the record in the database
                    final records = await DatabaseHelper.instance.getAllRecords();
                    records[index] = updatedRecord;
                    await DatabaseHelper.instance.saveRecords(records);
                    
                    // Refresh the UI
                    setState(() {
                      _records = records;
                    });

                    // Show success message if the context is still valid
                    if (mounted && context.mounted) {
                      // Use a post-frame callback to ensure we're in a safe state
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Auto path photo saved successfully'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      });
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Generate QR Code'),
              onTap: () {
                Navigator.pop(context);
                _showQRCodeDialog(context, record);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, ScoutingRecord record) {
    showDialog(
      context: context,
      builder: (context) => QRCodeDialog(record: record),
    );
  }

  void _showTeamAnalysis(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamAnalysisPage(records: _records),
      ),
    );
  }

  void _importData() async {
    try {
      final XTypeGroup csvTypeGroup = XTypeGroup(
        label: 'CSV',
        extensions: ['csv'],
        // Add UTIs for iOS
        uniformTypeIdentifiers: ['public.comma-separated-values-text'],
      );
      
      final XFile? file = await openFile(
        acceptedTypeGroups: [csvTypeGroup],
      );

      if (file != null) {
        final contents = await file.readAsString();
        
        final List<List<dynamic>> rows = const CsvToListConverter(fieldDelimiter: '|').convert(contents);
        if (rows.length <= 1) throw Exception('No data found in file');
        
        // Get existing records
        final existingRecords = await DatabaseHelper.instance.getAllRecords();
        
        // Convert new records from CSV
        final newRecords = rows.skip(1).map((row) => ScoutingRecord.fromCsvRow(row)).toList();
        
        // Combine existing and new records
        final allRecords = [...existingRecords, ...newRecords];
        
        // Save combined records
        await DatabaseHelper.instance.saveRecords(allRecords);
        
        setState(() {
          loadRecords();
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${newRecords.length} records'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing data: $e')),
      );
    }
  }

  void _exportData() async {
    try {
      if (Platform.isAndroid) {
        // Request storage permissions based on Android version
        if (await Permission.manageExternalStorage.isDenied) {
          final status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission is required to export data. Please grant permission in Settings.'),
                  duration: Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Settings',
                    onPressed: openAppSettings,
                  ),
                ),
              );
              return;
            }
          }
        }
      }

      final csvData = [
        ScoutingRecord.getCsvHeaders(),
        ..._records.map((r) => r.toCsvRow()),
      ];
      
      final csv = const ListToCsvConverter(fieldDelimiter: '|').convert(csvData);
      final String dirPath = await _getExportDirectory();
      
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      
      final file = File('$dirPath/scouting_data_$timestamp.csv');
      await file.writeAsString(csv);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Platform.isAndroid 
            ? 'Data exported to Documents → 2638 Scout → Exports'
            : 'Data exported to Files App → 2638 Scout → Exports'
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              Share.shareFiles(
                [file.path],
                text: 'Scouting Data Export',
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }

  Future<String> _getExportDirectory() async {
    if (Platform.isIOS) {
      // On iOS, create a directory in the Documents folder that will be visible in Files app
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${appDocDir.path}/2638 Scout/Exports';
      
      // Create the directory if it doesn't exist
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dirPath;
    } else if (Platform.isAndroid) {
      Directory? directory;
      
      try {
        // Use Documents directory with a clear path structure
        if (await Permission.manageExternalStorage.isGranted) {
          directory = Directory('/storage/emulated/0/Documents/2638 Scout/Exports');
        } else {
          // Fallback to app-specific directory
          final appDir = await getExternalStorageDirectory();
          if (appDir == null) {
            throw Exception('Could not access external storage');
          }
          directory = Directory('${appDir.path}/2638 Scout/Exports');
        }
        
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory.path;
      } catch (e) {
        // Fallback to app's private directory if all else fails
        final appDir = await getApplicationDocumentsDirectory();
        directory = Directory('${appDir.path}/2638 Scout/Exports');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory.path;
      }
    } else {
      // Fallback for other platforms
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      return '${appDocDir.path}/2638 Scout/Exports';
    }
  }

  Future<List<FileSystemEntity>> listExports() async {
    final String dirPath = await _getExportDirectory();
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return [];
    }
    return dir.listSync().where((e) => e.path.endsWith('.csv')).toList();
  }

  void _showDeleteConfirmation(BuildContext context, [int? index]) {
    final bool isMultipleDelete = selectedRecords.isNotEmpty;
    final int deleteCount = isMultipleDelete ? selectedRecords.length : 1;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMultipleDelete 
          ? 'Delete $deleteCount Records?' 
          : 'Delete Record?'
        ),
        content: Text(isMultipleDelete
          ? 'Are you sure you want to delete $deleteCount selected records? This cannot be undone.'
          : 'Are you sure you want to delete this record? This cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (isMultipleDelete) {
                  // get all records
                  final records = await DatabaseHelper.instance.getAllRecords();
                  
                  // create a new list with non-selected records
                  final updatedRecords = records.asMap().entries
                    .where((entry) => !selectedRecords.contains(entry.key))
                    .map((entry) => entry.value)
                    .toList();
                  
                  // save the filtered records
                  await DatabaseHelper.instance.saveRecords(updatedRecords);
                  
                  if (!mounted) return;
                  setState(() {
                    selectedRecords.clear();
                    _isSelectionMode = false;
                    loadRecords();
                  });
                } else if (index != null) {
                  final records = await DatabaseHelper.instance.getAllRecords();
                  records.removeAt(index);
                  await DatabaseHelper.instance.saveRecords(records);
                  
                  if (!mounted) return;
                  setState(() {
                    loadRecords();
                  });
                }
                
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isMultipleDelete
                      ? '$deleteCount records deleted'
                      : 'Record deleted'
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting record(s): $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete all scouting records. This action cannot be undone.\n\n'
          'Make sure you have exported your data if you want to keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              try {
                await DatabaseHelper.instance.deleteAllRecords();
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _records.clear();
                    selectedRecords.clear();
                    _isSelectionMode = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting data: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Delete All',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// Add this extension for median calculation
extension ListNumberExtension on List<num> {
  double median() {
    if (isEmpty) return 0;
    final sorted = List<num>.from(this)..sort();
    final middle = length ~/ 2;
    if (length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    }
    return sorted[middle].toDouble();
  }
}

class TeamNumberSelector extends StatelessWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;

  const TeamNumberSelector({
    Key? key,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        int? selected = await showDialog<int>(
          context: context,
          builder: (context) => TeamNumberSelectorDialog(
            initialValue: initialValue,
            onValueChanged: (value) {
              // This callback fires immediately when digits change.
              // (No extra action needed here.)
            },
          ),
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
      child: Text(initialValue.toString()),
    );
  }
}

// --- New stub for TeamNumberSelectorDialog ---
class TeamNumberSelectorDialog extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onValueChanged;

  const TeamNumberSelectorDialog({
    Key? key,
    required this.initialValue,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  _TeamNumberSelectorDialogState createState() => _TeamNumberSelectorDialogState();
}

class _TeamNumberSelectorDialogState extends State<TeamNumberSelectorDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Team Number"),
      content: Text("Team number selection dialog placeholder."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(widget.initialValue),
          child: Text("OK"),
        ),
      ],
    );
  }
}
