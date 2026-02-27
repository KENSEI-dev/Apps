import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  // UPDATE TO YOUR CORRECT IP!
  static const String pcIp = "192.168.31.242";  // ← YOUR WORKING IP
  
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';     // Chrome/Web
    return 'http://$pcIp:8000';                     // Android/Emulator
  }

  static Future<Map<String, dynamic>> getSleepAnalytics(String userId) async {
    final url = Uri.parse('$baseUrl/api/sleep/analytics/$userId');
    print('🌐 Calling: $url');  // Debug log
    
    final response = await http.get(url).timeout(Duration(seconds: 15));
    
    print('📡 Status: ${response.statusCode}');  // Debug log
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
