import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final Map<String, _MemEntry<String>> _memoryCache = {};
  static const Duration _defaultTtl = Duration(minutes: 5);

  static Future<T?> get<T>(String key, T Function(String) fromJson) async {
    final now = DateTime.now();

    final memEntry = _memoryCache[key];
    if (memEntry != null && now.isBefore(memEntry.expiry)) {
      return fromJson(memEntry.data);
    }
    _memoryCache.remove(key);

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cache_$key');
      if (raw == null) return null;

      final entry = _PersistedEntry.fromJson(jsonDecode(raw));
      if (now.isBefore(entry.expiry)) {
        _memoryCache[key] = _MemEntry(entry.json, entry.expiry);
        return fromJson(entry.json);
      }

      prefs.remove('cache_$key');
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> set(String key, String json, {Duration? ttl}) async {
    final expiry = DateTime.now().add(ttl ?? _defaultTtl);
    _memoryCache[key] = _MemEntry(json, expiry);

    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = _PersistedEntry(json: json, expiry: expiry);
      await prefs.setString('cache_$key', jsonEncode(entry.toJson()));
    } catch (_) {}
  }

  static Future<void> remove(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
    } catch (_) {}
  }

  static Future<void> clear() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}

class _MemEntry<T> {
  final T data;
  final DateTime expiry;
  _MemEntry(this.data, this.expiry);
}

class _PersistedEntry {
  final String json;
  final DateTime expiry;

  _PersistedEntry({required this.json, required this.expiry});

  factory _PersistedEntry.fromJson(Map<String, dynamic> json) {
    return _PersistedEntry(
      json: json['json']?.toString() ?? '',
      expiry: DateTime.tryParse(json['expiry']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'json': json,
    'expiry': expiry.toIso8601String(),
  };
}
