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
  static void Function(String?)? onSyncProgress;

  static const int _maxRetries = 5;
  static final Map<int, int> _retryCount = {};

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
      if (pending.isEmpty) { _resetRetries(); return; }

      for (int i = 0; i < pending.length; i++) {
        final row = pending[i];
        final id = (row['id'] as int?) ?? 0;
        if (id == 0) continue;

        final retries = _retryCount[id] ?? 0;
        if (retries >= _maxRetries) {
          _retryCount.remove(id);
          continue;
        }

        try {
          onSyncProgress?.call('Syncing ${i + 1} of ${pending.length}...');
          final date = row['date']?.toString() ?? '';
          final recordsRaw = row['records']?.toString() ?? '[]';
          final records = jsonDecode(recordsRaw);
          final recordList = records is List ? records : [];
          final res = await http.post(
            Uri.parse('${ApiService.baseUrl}/attendance'),
            headers: AuthService.authHeaders,
            body: jsonEncode({'date': date, 'records': recordList}),
          ).timeout(const Duration(seconds: 60));
          if (res.statusCode == 200 || res.statusCode == 201) {
            await OfflineDb.markSynced(id);
            _retryCount.remove(id);
            ApiService.clearCache();
          } else {
            _retryCount[id] = retries + 1;
          }
        } catch (_) {
          _retryCount[id] = retries + 1;
          if (_retryCount[id]! < _maxRetries) {
            await Future.delayed(Duration(seconds: _backoff(retries)));
          }
          rethrow;
        }
      }
    } finally {
      _syncing = false;
      onSyncProgress?.call(null);
    }
  }

  static int _backoff(int attempt) {
    const base = 2;
    final delay = base * (1 << attempt);
    return delay.clamp(2, 60);
  }

  static void _resetRetries() {
    _retryCount.clear();
  }

  static Future<void> syncNow() async {
    await _sync();
  }
}
