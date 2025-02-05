import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
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
    final String? csvData = prefs.getString(_storageKey);
    if (csvData == null) return [];
    
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);
    if (rows.isEmpty) return [];
    
    // Skip header row
    return rows.skip(1).map((row) => ScoutingRecord.fromCsvRow(row)).toList();
  }

  Future<void> saveRecords(List<ScoutingRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final csvData = [
      ScoutingRecord.getCsvHeaders(),
      ...records.map((r) => r.toCsvRow()),
    ];
    
    final csv = const ListToCsvConverter().convert(csvData);
    await prefs.setString(_storageKey, csv);
  }
} 