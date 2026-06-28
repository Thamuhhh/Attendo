import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';
import 'offline_db.dart';

class SyncService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _syncing = false;
  static bool _isOnline = true;
  static void Function(bool)? onStatusChanged;

  static bool get isOnline => _isOnline;

  static void start() {
    _connectivity.checkConnectivity().then((results) => _checkStatus(results));
    _subscription = _connectivity.onConnectivityChanged.listen(_onChange);
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  static void _onChange(List<ConnectivityResult> results) {
    _checkStatus(results);
  }

  static Future<void> _checkStatus(List<ConnectivityResult> results) async {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);
    if (_isOnline != wasOnline) {
      onStatusChanged?.call(_isOnline);
    }
    if (_isOnline && !wasOnline) {
      unawaited(_sync());
    }
  }

  static Future<void> _sync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final pending = await OfflineDb.getUnsyncedRecords();
      for (final row in pending) {
        try {
          final id = row['id'] as int;
          final date = row['date'] as String;
          final records = jsonDecode(row['records'] as String) as List;
          final res = await http.post(
            Uri.parse('${ApiService.baseUrl}/attendance'),
            headers: AuthService.authHeaders,
            body: jsonEncode({'date': date, 'records': records}),
          ).timeout(const Duration(seconds: 60));
          if (res.statusCode == 200 || res.statusCode == 201) {
            await OfflineDb.markSynced(id);
            ApiService.clearCache();
          }
        } catch (_) {}
      }
    } finally {
      _syncing = false;
    }
  }

  static Future<void> syncNow() async {
    await _sync();
  }
}
