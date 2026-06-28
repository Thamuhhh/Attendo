import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class OfflineDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'attendo_offline.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            records TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<int> saveAttendance(String date, List<Map<String, dynamic>> records) async {
    final db = await database;
    return db.insert('pending_attendance', {
      'date': date,
      'records': jsonEncode(records),
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final db = await database;
    return db.query('pending_attendance', where: 'synced = 0', orderBy: 'created_at ASC');
  }

  static Future<void> markSynced(int id) async {
    final db = await database;
    await db.update('pending_attendance', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('pending_attendance', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> pendingCount() async {
    final db = await database;
    final result = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pending_attendance WHERE synced = 0'));
    return result ?? 0;
  }

  static Future<void> deleteSyncedOlderThan(Duration duration) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(duration).toIso8601String();
    await db.delete('pending_attendance', where: 'synced = 1 AND created_at < ?', whereArgs: [cutoff]);
  }
}
