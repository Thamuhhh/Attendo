import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../models/fee_record.dart';
import 'auth_service.dart';

class ApiService {
  static String _customBase = '';
  static const String productionUrl = 'https://attendo-e4ts.onrender.com/api';
  static Timer? _keepAliveTimer;
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(seconds: 30);

  static void startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      http.get(Uri.parse('$productionUrl/auth/me'), headers: AuthService.authHeaders).timeout(const Duration(seconds: 10)).catchError((_) {});
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

  static Future<T> _cached<T>(String key, Future<T> Function() fetcher) async {
    final now = DateTime.now();
    final entry = _cache[key];
    if (entry != null && now.difference(entry.time) < _cacheDuration) {
      return entry.data as T;
    }
    final data = await fetcher();
    _cache[key] = _CacheEntry(data, now);
    return data;
  }

  static void clearCache() => _cache.clear();

  static Future<String?> _offlineGet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('offline_$key');
  }

  static Future<void> _offlineSet(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_$key', data);
  }

  static Future<String> _fetchRaw(String url) async {
    final res = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 60));
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
    return (jsonDecode(body) as List).map((e) => Student.fromJson(e)).toList();
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
    return _cached<TodayAttendance>('today_attendance', () async {
      final body = await _fetchRawWithFallback('today_attendance', '$baseUrl/attendance/today');
      return TodayAttendance.fromJson(jsonDecode(body));
    });
  }

  static Future<List<AttendanceRecord>> getAttendanceByDate(String date) async {
    final body = await _fetchRawWithFallback('attendance_$date', '$baseUrl/attendance?date=$date');
    return (jsonDecode(body) as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  static Future<void> saveAttendance(String date, List<Map<String, dynamic>> records) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance'),
      headers: _headers,
      body: jsonEncode({'date': date, 'records': records}),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw Exception('Failed to save attendance');
    clearCache();
  }

  static Future<MonthlyReport> getMonthlyReport(int year, int month) async {
    final key = 'monthly_${year}_$month';
    final body = await _fetchRawWithFallback(key, '$baseUrl/report/monthly?year=$year&month=$month');
    return MonthlyReport.fromJson(jsonDecode(body));
  }

  static Future<FeeSummary> getFeeSummary(int year) async {
    return _cached<FeeSummary>('fee_summary_$year', () async {
      final body = await _fetchRawWithFallback('fee_summary_$year', '$baseUrl/fees/summary?year=$year');
      return FeeSummary.fromJson(jsonDecode(body));
    });
  }

  static Future<List<FeeRecord>> getFeeRecords(String studentId, int year) async {
    final body = await _fetchRawWithFallback('fees_${studentId}_$year', '$baseUrl/fees?studentId=$studentId&year=$year');
    return (jsonDecode(body) as List).map((e) => FeeRecord.fromJson(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> getWeeklyAttendance() async {
    return _cached<List<Map<String, dynamic>>>('weekly_attendance', () async {
      final body = await _fetchRawWithFallback('weekly_attendance', '$baseUrl/attendance/weekly');
      return (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    });
  }

  static Future<void> saveFees(List<Map<String, dynamic>> records) async {
    final res = await http.post(
      Uri.parse('$baseUrl/fees'),
      headers: _headers,
      body: jsonEncode({'records': records}),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw Exception('Failed to save fees');
  }

  static Future<List<String>> getHolidays() async {
    final body = await _fetchRawWithFallback('holidays', '$baseUrl/holidays');
    return (jsonDecode(body) as List).cast<String>();
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

  static Future<List<Map<String, dynamic>>> getAttendanceHistory(String studentId, {int? year, int? month}) async {
    String url = '$baseUrl/attendance/history/$studentId';
    if (year != null && month != null) url += '?year=$year&month=$month';
    final body = await _fetchRawWithFallback('att_history_$studentId', url);
    return (jsonDecode(body) as List).cast<Map<String, dynamic>>();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime time;
  _CacheEntry(this.data, this.time);
}

