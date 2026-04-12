import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.2.2:8000';
  }
  static Future<List<dynamic>> getStops() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/stops'));
      developer.log('API Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('API returned ${response.statusCode}');
    } catch (e) {
      developer.log('API Error: $e');
      throw Exception('Failed to load stops: $e');
    }
  }

  static Future<Map<String, dynamic>> reportCrowd({
    required int stopId,
    required int crowdLevel,
    required double lat,
    required double lon,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/report/crowd'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'stop_id': stopId,
        'crowd_level': crowdLevel,
        'latitude': lat,
        'longitude': lon,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to report: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> getAllRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/route/all?start_lat=$startLat&start_lon=$startLon&end_lat=$endLat&end_lon=$endLon',
        ),
      );
      developer.log('Routes Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get routes: ${response.statusCode}');
    } catch (e) {
      developer.log('Route Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getTrafficAnalysis() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/traffic/analysis'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get traffic analysis');
    } catch (e) {
      rethrow;
    }
  }
}