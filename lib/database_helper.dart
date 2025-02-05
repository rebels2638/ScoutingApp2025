import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const String _storageKey = 'scouting_records';

  DatabaseHelper._init();

  Future<void> deleteAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<List<ScoutingRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recordsJson = prefs.getString(_storageKey);
    if (recordsJson == null) return [];
    
    List<dynamic> decoded = jsonDecode(recordsJson);
    return decoded.map((json) => ScoutingRecord.fromJson(json)).toList();
  }

  Future<void> saveRecords(List<ScoutingRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
} 