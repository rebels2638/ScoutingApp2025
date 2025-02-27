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
    if (csvData == null || csvData.isEmpty) return [];
    
    final List<List<dynamic>> rows = const CsvToListConverter(fieldDelimiter: '|').convert(csvData);
    if (rows.isEmpty || rows.length <= 1) return [];
    
    return rows.skip(1).map((row) {
      try {
        return ScoutingRecord.fromCsvRow(row);
      } catch (e) {
        print('Error parsing row: $e');
        return null;
      }
    }).where((record) => record != null).cast<ScoutingRecord>().toList();
  }

  Future<void> saveRecords(List<ScoutingRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final csvData = [
      ScoutingRecord.getCsvHeaders(),
      ...records.map((r) => r.toCsvRow()),
    ];
    
    final csv = const ListToCsvConverter(fieldDelimiter: '|').convert(csvData);
    await prefs.setString(_storageKey, csv);
  }
} 