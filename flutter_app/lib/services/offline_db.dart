import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/reminder_profile.dart';

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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            records TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await _createRemindersTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createRemindersTable(db);
        }
        if (oldVersion < 3) {
          try { await db.execute('ALTER TABLE pending_attendance ADD COLUMN retry_count INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE pending_attendance ADD COLUMN last_error TEXT'); } catch (_) {}
        }
      },
    );
  }

  static Future<void> _createRemindersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminder_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL DEFAULT 'Reminder',
        hour INTEGER NOT NULL DEFAULT 18,
        minute INTEGER NOT NULL DEFAULT 0,
        days_mask INTEGER NOT NULL DEFAULT 127,
        enabled INTEGER NOT NULL DEFAULT 1,
        smart_enabled INTEGER NOT NULL DEFAULT 0,
        smart_gap_days INTEGER NOT NULL DEFAULT 2
      )
    ''');
    await db.insert('reminder_profiles', {
      'label': 'Evening Reminder',
      'hour': 18, 'minute': 0,
      'days_mask': 127, 'enabled': 1,
      'smart_enabled': 0, 'smart_gap_days': 2,
    });
  }

  static Future<int> saveAttendance(String date, List<Map<String, dynamic>> records) async {
    final db = await database;
    return db.insert('pending_attendance', {
      'date': date,
      'records': jsonEncode(records),
      'synced': 0,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> incrementRetry(int id, String? error) async {
    final db = await database;
    final rows = await db.query('pending_attendance', columns: ['retry_count'], where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final count = (rows.first['retry_count'] as int? ?? 0) + 1;
    await db.update(
      'pending_attendance',
      {'retry_count': count, 'last_error': error},
      where: 'id = ?', whereArgs: [id],
    );
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

  static Future<List<ReminderProfile>> getReminders() async {
    final db = await database;
    final rows = await db.query('reminder_profiles', orderBy: 'id ASC');
    return rows.map((r) => ReminderProfile.fromMap(r)).toList();
  }

  static Future<ReminderProfile?> getReminder(int id) async {
    final db = await database;
    final rows = await db.query('reminder_profiles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ReminderProfile.fromMap(rows.first);
  }

  static Future<int> insertReminder(ReminderProfile p) async {
    final db = await database;
    return db.insert('reminder_profiles', p.toMap());
  }

  static Future<void> updateReminder(ReminderProfile p) async {
    final db = await database;
    await db.update('reminder_profiles', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  static Future<void> deleteReminder(int id) async {
    final db = await database;
    await db.delete('reminder_profiles', where: 'id = ?', whereArgs: [id]);
  }
}
