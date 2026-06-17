import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../models/fee_record.dart';
import 'auth_service.dart';

class ApiService {
  static String _customBase = '';

  static String get baseUrl {
    if (_customBase.isNotEmpty) return _customBase;

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static void setBaseUrl(String url) {
    _customBase = url.endsWith('/api') ? url : '$url/api';
  }

  static Map<String, String> get _headers => AuthService.authHeaders;

  static Future<List<Student>> getStudents() async {
    final res = await http.get(Uri.parse('$baseUrl/students'), headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => Student.fromJson(e)).toList();
    }
    throw Exception('Failed to load students (${res.statusCode})');
  }

  static Future<Student> addStudent(String name, String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/students'),
      headers: _headers,
      body: jsonEncode({'name': name, 'phone': phone}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return Student.fromJson(jsonDecode(res.body));
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to add student');
  }

  static Future<Student> updateStudent(String id, String name, String phone) async {
    final res = await http.put(
      Uri.parse('$baseUrl/students/$id'),
      headers: _headers,
      body: jsonEncode({'name': name, 'phone': phone}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return Student.fromJson(jsonDecode(res.body));
    throw Exception('Failed to update student');
  }

  static Future<void> deleteStudent(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/students/$id'), headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Failed to delete student');
  }

  static Future<TodayAttendance> getTodayAttendance() async {
    final res = await http.get(Uri.parse('$baseUrl/attendance/today'), headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return TodayAttendance.fromJson(jsonDecode(res.body));
    throw Exception('Failed to load today attendance');
  }

  static Future<List<AttendanceRecord>> getAttendanceByDate(String date) async {
    final res = await http.get(Uri.parse('$baseUrl/attendance?date=$date'), headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => AttendanceRecord.fromJson(e)).toList();
    }
    throw Exception('Failed to load attendance');
  }

  static Future<void> saveAttendance(String date, List<Map<String, dynamic>> records) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance'),
      headers: _headers,
      body: jsonEncode({'date': date, 'records': records}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Failed to save attendance');
  }

  static Future<MonthlyReport> getMonthlyReport(int year, int month) async {
    final res = await http.get(Uri.parse('$baseUrl/report/monthly?year=$year&month=$month'), headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return MonthlyReport.fromJson(jsonDecode(res.body));
    throw Exception('Failed to load report');
  }

  static Future<FeeSummary> getFeeSummary(int year) async {
    final res = await http.get(Uri.parse('$baseUrl/fees/summary?year=$year'), headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return FeeSummary.fromJson(jsonDecode(res.body));
    throw Exception('Failed to load fee summary');
  }

  static Future<List<FeeRecord>> getFeeRecords(String studentId, int year) async {
    final res = await http.get(Uri.parse('$baseUrl/fees?studentId=$studentId&year=$year'), headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => FeeRecord.fromJson(e)).toList();
    }
    throw Exception('Failed to load fee records');
  }

  static Future<void> saveFees(List<Map<String, dynamic>> records) async {
    final res = await http.post(
      Uri.parse('$baseUrl/fees'),
      headers: _headers,
      body: jsonEncode({'records': records}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Failed to save fees');
  }
}
