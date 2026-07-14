import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../models/fee_record.dart';
import 'auth_service.dart';
import 'cache_service.dart';

class ApiService {
  static String _customBase = '';
  static const String productionUrl = 'https://attendo-e4ts.onrender.com/api';
  static Timer? _keepAliveTimer;

  static void startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      http.get(Uri.parse('$productionUrl/auth/me'), headers: AuthService.authHeaders).timeout(const Duration(seconds: 10)).then((_) {}, onError: (_) {});
    });
  }

  static Future<void> warmUp() async {
    try {
      await http.get(Uri.parse('$productionUrl/auth/me'), headers: AuthService.authHeaders).timeout(const Duration(seconds: 60));
    } catch (_) {}
  }

  static void stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  static Future<void> clearCache() => CacheService.clear();

  static Future<String?> _offlineGet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('offline_$key');
  }

  static Future<void> _offlineSet(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_$key', data);
  }

  static Future<String> _fetchRaw(String url) async {
    var res = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 60));
    if (res.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 5));
      res = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 60));
    }
    if (res.statusCode == 200) return res.body;
    throw Exception('Request failed ($url): ${res.statusCode}');
  }

  static Future<String> _fetchRawWithFallback(String cacheKey, String url) async {
    try {
      final body = await _fetchRaw(url);
      await _offlineSet(cacheKey, body);
      return body;
    } catch (e) {
      final cached = await _offlineGet(cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }

  static String get baseUrl {
    return _customBase.isNotEmpty ? _customBase : productionUrl;
  }

  static void useLocalhost() {
    _customBase = Platform.isAndroid ? 'http://10.0.2.2:3000/api' : 'http://localhost:3000/api';
  }

  static void setBaseUrl(String url) {
    _customBase = url.endsWith('/api') ? url : '$url/api';
  }

  static Map<String, String> get _headers => AuthService.authHeaders;

  static Future<List<Student>> getStudents() async {
    final body = await _fetchRawWithFallback('students', '$baseUrl/students');
    final list = jsonDecode(body);
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map((e) => Student.fromJson(e)).toList();
  }

  static Future<Student> addStudent(String name, String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/students'),
      headers: _headers,
      body: jsonEncode({'name': name, 'phone': phone}),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode == 200) return Student.fromJson(jsonDecode(res.body));
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to add student');
  }

  static Future<Student> updateStudent(String id, String name, String phone) async {
    final res = await http.put(
      Uri.parse('$baseUrl/students/$id'),
      headers: _headers,
      body: jsonEncode({'name': name, 'phone': phone}),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode == 200) return Student.fromJson(jsonDecode(res.body));
    throw Exception('Failed to update student');
  }

  static Future<void> deleteStudent(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/students/$id'), headers: _headers).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw Exception('Failed to delete student');
  }

  static Future<TodayAttendance> getTodayAttendance() async {
    final cached = await CacheService.get<TodayAttendance>('today_attendance', (s) => TodayAttendance.fromJson(jsonDecode(s)));
    if (cached != null) return cached;
    final body = await _fetchRawWithFallback('today_attendance', '$baseUrl/attendance/today');
    final data = TodayAttendance.fromJson(jsonDecode(body));
    await CacheService.set('today_attendance', body, ttl: const Duration(seconds: 30));
    return data;
  }

  static Future<List<AttendanceRecord>> getAttendanceByDate(String date) async {
    final body = await _fetchRawWithFallback('attendance_$date', '$baseUrl/attendance?date=$date');
    final list = jsonDecode(body);
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  static Future<void> saveAttendance(String date, List<Map<String, dynamic>> records) async {
    var res = await http.post(
      Uri.parse('$baseUrl/attendance'),
      headers: _headers,
      body: jsonEncode({'date': date, 'records': records}),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 5));
      res = await http.post(
        Uri.parse('$baseUrl/attendance'),
        headers: _headers,
        body: jsonEncode({'date': date, 'records': records}),
      ).timeout(const Duration(seconds: 60));
    }
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('Failed to save attendance');
    await clearCache();
  }

  static Future<MonthlyReport> getMonthlyReport(int year, int month) async {
    final key = 'monthly_${year}_$month';
    final body = await _fetchRawWithFallback(key, '$baseUrl/report/monthly?year=$year&month=$month');
    return MonthlyReport.fromJson(jsonDecode(body));
  }

  static Future<FeeSummary> getFeeSummary(int year) async {
    final cacheKey = 'fee_summary_$year';
    final cached = await CacheService.get<FeeSummary>(cacheKey, (s) => FeeSummary.fromJson(jsonDecode(s)));
    if (cached != null) return cached;
    final body = await _fetchRawWithFallback(cacheKey, '$baseUrl/fees/summary?year=$year');
    final data = FeeSummary.fromJson(jsonDecode(body));
    await CacheService.set(cacheKey, body, ttl: const Duration(minutes: 2));
    return data;
  }

  static Future<List<FeeRecord>> getFeeRecords(String studentId, int year) async {
    final body = await _fetchRawWithFallback('fees_${studentId}_$year', '$baseUrl/fees?studentId=$studentId&year=$year');
    final list = jsonDecode(body);
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map((e) => FeeRecord.fromJson(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> getWeeklyAttendance() async {
    final cached = await CacheService.get<List<Map<String, dynamic>>>('weekly_attendance', (s) {
      final list = jsonDecode(s);
      if (list is! List) return <Map<String, dynamic>>[];
      return list.whereType<Map<String, dynamic>>().toList();
    });
    if (cached != null) return cached;
    final body = await _fetchRawWithFallback('weekly_attendance', '$baseUrl/attendance/weekly');
    final list = jsonDecode(body);
    final data = list is List ? list.whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];
    await CacheService.set('weekly_attendance', body, ttl: const Duration(seconds: 30));
    return data;
  }

  static Future<void> saveFees(List<Map<String, dynamic>> records) async {
    var res = await http.post(
      Uri.parse('$baseUrl/fees'),
      headers: _headers,
      body: jsonEncode({'records': records}),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 5));
      res = await http.post(
        Uri.parse('$baseUrl/fees'),
        headers: _headers,
        body: jsonEncode({'records': records}),
      ).timeout(const Duration(seconds: 60));
    }
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('Failed to save fees');
    await clearCache();
  }

  static Future<List<String>> getHolidays() async {
    final body = await _fetchRawWithFallback('holidays', '$baseUrl/holidays');
    final list = jsonDecode(body);
    if (list is! List) return [];
    return list.whereType<String>().toList();
  }

  static Future<void> addHoliday(String date) async {
    final res = await http.post(
      Uri.parse('$baseUrl/holidays'),
      headers: _headers,
      body: jsonEncode({'date': date}),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw Exception('Failed to add holiday');
    clearCache();
  }

  static Future<void> removeHoliday(String date) async {
    final res = await http.delete(Uri.parse('$baseUrl/holidays/$date'), headers: _headers).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw Exception('Failed to remove holiday');
    clearCache();
  }

  static Future<Map<String, dynamic>> claimOldData() async {
    final res = await http.post(
      Uri.parse('$baseUrl/migrate/claim'),
      headers: _headers,
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Claim failed');
  }

  static Future<List<Map<String, dynamic>>> getAttendanceHistory(String studentId, {int? year, int? month}) async {
    String url = '$baseUrl/attendance/history/$studentId';
    if (year != null && month != null) url += '?year=$year&month=$month';
    final body = await _fetchRawWithFallback('att_history_$studentId', url);
    final list = jsonDecode(body);
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  static Future<Map<String, dynamic>> getAppVersion() async {
    final res = await http.get(
      Uri.parse('$baseUrl/app/version'),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to get app version');
  }
}

