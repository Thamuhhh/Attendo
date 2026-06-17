import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _instNameKey = 'inst_name';
  static const _instEmailKey = 'inst_email';

  static String? _token;
  static String? _instName;
  static String? _instEmail;

  static bool get isLoggedIn => _token != null;
  static String? get token => _token;
  static String? get institutionName => _instName;
  static String? get institutionEmail => _instEmail;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _instName = prefs.getString(_instNameKey);
    _instEmail = prefs.getString(_instEmailKey);
  }

  static Future<bool> register(String name, String email, String phone, String password) async {
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'phone': phone, 'password': password}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveToken(data['token'], data['institution']['name'], data['institution']['email']);
      return true;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Registration failed');
  }

  static Future<bool> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveToken(data['token'], data['institution']['name'], data['institution']['email']);
      return true;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Login failed');
  }

  static Future<void> logout() async {
    _token = null;
    _instName = null;
    _instEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_instNameKey);
    await prefs.remove(_instEmailKey);
  }

  static Future<void> _saveToken(String token, String name, String email) async {
    _token = token;
    _instName = name;
    _instEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_instNameKey, name);
    await prefs.setString(_instEmailKey, email);
  }

  static Map<String, String> get authHeaders {
    if (_token != null) {
      return {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'};
    }
    return {'Content-Type': 'application/json'};
  }
}
