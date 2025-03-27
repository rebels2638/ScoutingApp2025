import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data.dart';

class PitScoutService {
  static const String _storageKey = 'pit_scout_data';
  static PitScoutService? _instance;
  Map<int, PitScoutData> _pitScoutData = {};

  PitScoutService._();

  static PitScoutService get instance {
    _instance ??= PitScoutService._();
    return _instance!;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      _pitScoutData = {
        for (var json in jsonList)
          PitScoutData.fromJson(json).teamNumber: PitScoutData.fromJson(json)
      };
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _pitScoutData.values.map((data) => data.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> importCsv(String csvString) async {
    final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
    if (csvTable.isEmpty || csvTable[0].isEmpty) return;

    // get headers from first row
    final headers = csvTable[0].map((e) => e.toString()).toList();

    // process each row
    for (var i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      if (row.length != headers.length) continue;

      // create map of header to value
      final Map<String, dynamic> rowData = {
        for (var j = 0; j < headers.length; j++)
          headers[j]: row[j]
      };

      final pitScoutData = PitScoutData.fromCsv(rowData);
      if (pitScoutData.teamNumber > 0) {
        _pitScoutData[pitScoutData.teamNumber] = pitScoutData;
      }
    }

    await saveData();
  }

  PitScoutData? getDataForTeam(int teamNumber) {
    return _pitScoutData[teamNumber];
  }

  List<PitScoutData> getAllData() {
    return _pitScoutData.values.toList();
  }

  void clearData() {
    _pitScoutData.clear();
  }

  Future<void> deleteAllData() async {
    _pitScoutData.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
} 