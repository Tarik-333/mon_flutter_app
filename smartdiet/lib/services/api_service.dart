import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  // ✅ Pixel 5 Emulator (Android) => 10.0.2.2
  // ✅ Backend FastAPI tourne sur port 8000
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // -------------------------
  // AUTH
  // -------------------------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/login');

    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Login failed (${res.statusCode}): ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Token missing in response');
    }
    setToken(accessToken);
    return data;
  }

  /// Register backend attend plusieurs champs.
  /// Comme ton écran register ne demande que name/email/password,
  /// on met des valeurs par défaut (tu les modifies après dans ProfileSetup).
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    int age = 21,
    double weight = 70.0,
    double height = 171.0,
    String gender = 'homme',
    String goal = 'maintien', // perte / prise / maintien
    String activityLevel = 'modéré', // sédentaire / modéré / actif / très actif
  }) async {
    final url = Uri.parse('$baseUrl/api/register');

    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'age': age,
        'weight': weight,
        'height': height,
        'gender': gender,
        'goal': goal,
        'activity_level': activityLevel,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Register failed (${res.statusCode}): ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Token missing in response');
    }
    setToken(accessToken);
    return data;
  }

  // -------------------------
  // USER
  // -------------------------
  static Future<Map<String, dynamic>> getMe() async {
    final url = Uri.parse('$baseUrl/api/user/me');
    final res = await http.get(url, headers: _headers(auth: true));

    if (res.statusCode != 200) {
      throw Exception('getMe failed (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getGoals() async {
    final url = Uri.parse('$baseUrl/api/user/goals');
    final res = await http.get(url, headers: _headers(auth: true));

    if (res.statusCode != 200) {
      throw Exception('getGoals failed (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/user/me');
    final res = await http.put(
      url,
      headers: _headers(auth: true),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('updateMe failed (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
