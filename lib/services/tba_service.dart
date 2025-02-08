import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TBAService {
  static const String _baseUrl = 'https://www.thebluealliance.com/api/v3';
  static const String _apiKey = 'lSSNDcw30oSlwiLWdrmgFA2X613C35GT92cYaNZBLETy5sIF80UWWZne8753n8wn';
  static const String _cachePrefix = 'tba_cache_';
  
  // Cache duration - 24 hours
  static const Duration _cacheDuration = Duration(hours: 24);

  Future<dynamic> _getFromApi(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'X-TBA-Auth-Key': _apiKey},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return null; // Return null for not found
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> _getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_cachePrefix$key');
    if (data != null) {
      final cached = json.decode(data);
      if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cached['timestamp'])) < _cacheDuration) {
        return cached['data'];
      }
    }
    throw Exception('Cache miss or expired');
  }

  Future<void> _cacheData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    await prefs.setString('$_cachePrefix$key', json.encode(cacheData));
  }

  Future<Map<String, dynamic>?> getTeamInfo(int teamNumber) async {
    // Pad team number to 4 digits
    final paddedNumber = teamNumber.toString().padLeft(4, '0');
    final endpoint = '/team/frc$paddedNumber';
    try {
      final data = await _getCachedData(endpoint);
      return Map<String, dynamic>.from(data);
    } catch (e) {
      final data = await _getFromApi(endpoint);
      if (data != null) {
        await _cacheData(endpoint, data);
        return Map<String, dynamic>.from(data);
      }
      return null;
    }
  }

  Future<List<dynamic>?> getTeamEvents(int teamNumber, int year) async {
    final endpoint = '/team/frc$teamNumber/events/$year';
    try {
      final data = await _getCachedData(endpoint);
      return List<dynamic>.from(data);
    } catch (e) {
      final data = await _getFromApi(endpoint);
      if (data != null) {
        await _cacheData(endpoint, data);
        return List<dynamic>.from(data);
      }
      return null;
    }
  }

  Future<List<dynamic>> getEventTeams(String eventKey) async {
    final endpoint = '/event/$eventKey/teams';
    try {
      final data = await _getCachedData(endpoint);
      return List<dynamic>.from(data);
    } catch (e) {
      final data = await _getFromApi(endpoint);
      await _cacheData(endpoint, data);
      return List<dynamic>.from(data);
    }
  }
} 