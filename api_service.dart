import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    const pcIp = "10.150.21.116";
    return kIsWeb ? 'http://127.0.0.1:8000' : 'http://$pcIp:8000';
  }

  static Future<Map<String, dynamic>> addSleep(int minutes) async {
    final response = await http.get(Uri.parse('$baseUrl/api/sleep/add/$minutes'));
    return jsonDecode(response.body);
  }
}
