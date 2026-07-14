import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'push_notification_service.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _instIdKey = 'inst_id';
  static const _instNameKey = 'inst_name';
  static const _instEmailKey = 'inst_email';

  static String? _token;
  static String? _refreshToken;
  static String? _instId;
  static String? _instName;
  static String? _instEmail;

  static bool get isLoggedIn => _token != null;
  static String? get token => _token;
  static String? get refreshToken => _refreshToken;
  static String? get institutionId => _instId;
  static String? get institutionName => _instName;
  static String? get institutionEmail => _instEmail;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    _instId = prefs.getString(_instIdKey);
    _instName = prefs.getString(_instNameKey);
    _instEmail = prefs.getString(_instEmailKey);
  }

  static Map<String, dynamic> _parseAuthResponse(Map<String, dynamic> data) {
    final accessToken = (data['accessToken'] ?? data['token'])?.toString();
    final refreshToken = data['refreshToken']?.toString();
    final inst = data['institution'];
    final instMap = inst is Map<String, dynamic> ? inst : <String, dynamic>{};
    final instId = instMap['id']?.toString() ?? instMap['_id']?.toString() ?? '';
    final instName = instMap['name']?.toString() ?? '';
    final instEmail = instMap['email']?.toString() ?? '';
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Login failed: invalid server response');
    }
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken ?? '',
      'instId': instId,
      'name': instName,
      'email': instEmail,
    };
  }

  static Future<bool> register(
      String name, String email, String phone, String password) async {
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'name': name, 'email': email, 'phone': phone, 'password': password}),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final parsed = _parseAuthResponse(data);
      await _saveTokens(
        parsed['accessToken'].toString(),
        parsed['refreshToken'].toString(),
        parsed['instId'].toString(),
        parsed['name'].toString(),
        parsed['email'].toString(),
      );
      PushNotificationService().sendTokenToServer().catchError((_) {});
      return true;
    }
    final err = jsonDecode(res.body);
    throw Exception(err is Map ? err['error'] ?? 'Registration failed' : 'Registration failed');
  }

  static Future<bool> login(String email, String password) async {
    var res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 5));
      res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 60));
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final parsed = _parseAuthResponse(data);
      await _saveTokens(
        parsed['accessToken'].toString(),
        parsed['refreshToken'].toString(),
        parsed['instId'].toString(),
        parsed['name'].toString(),
        parsed['email'].toString(),
      );
      PushNotificationService().sendTokenToServer().catchError((_) {});
      return true;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Login failed');
  }

  static Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        await http
            .post(
              Uri.parse('${ApiService.baseUrl}/auth/logout'),
              headers: authHeaders,
              body: jsonEncode({'refreshToken': _refreshToken}),
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {}

    PushNotificationService().removeTokenFromServer().catchError((_) {});

    _token = null;
    _refreshToken = null;
    _instId = null;
    _instName = null;
    _instEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_instIdKey);
    await prefs.remove(_instNameKey);
    await prefs.remove(_instEmailKey);
  }

  static Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newToken = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newToken == null || newToken.isEmpty) return false;
        _token = newToken;
        _refreshToken = newRefresh ?? _refreshToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_refreshTokenKey, _refreshToken!);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> _saveTokens(String accessToken, String refToken,
      String instId, String name, String email) async {
    _token = accessToken;
    _refreshToken = refToken;
    _instId = instId;
    _instName = name;
    _instEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refToken);
    await prefs.setString(_instIdKey, instId);
    await prefs.setString(_instNameKey, name);
    await prefs.setString(_instEmailKey, email);
  }

  static Map<String, String> get authHeaders {
    if (_token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token'
      };
    }
    return {'Content-Type': 'application/json'};
  }

  static Future<http.Response> authenticatedRequest(
      Future<http.Response> Function() request) async {
    var response = await request();
    if (response.statusCode == 401 &&
        response.body.contains('TOKEN_EXPIRED')) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await request();
      }
    }
    if (response.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 5));
      response = await request();
    }
    return response;
  }
}
