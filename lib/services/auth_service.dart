import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/auth_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const storage = FlutterSecureStorage();

  static Future<AuthResponse> signup(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.signupEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await storage.write(key: 'token', value: authResponse.accessToken);
        return authResponse;
      } else {
        throw Exception('Signup failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during signup: $e');
    }
  }

  static Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await storage.write(key: 'token', value: authResponse.accessToken);
        return authResponse;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  static Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  static Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}