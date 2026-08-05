import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:univ_tiaret/db/db_helper.dart';

class ProfileRepository {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<void> upsert(Map<String, dynamic> profile) async {
    final db = await _db.database;
    profile['updated_at'] = DateTime.now().toIso8601String();
    if (profile['roles'] is List) {
      profile['roles'] = jsonEncode(profile['roles']);
    }
    await db.insert(
      'user_profile',
      profile,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> get() async {
    final db = await _db.database;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    final row = Map<String, dynamic>.from(rows.first);
    if (row['roles'] is String) {
      row['roles'] = jsonDecode(row['roles'] as String);
    }
    return row;
  }

  static Future<void> updateFields(Map<String, dynamic> fields) async {
    final db = await _db.database;
    fields['updated_at'] = DateTime.now().toIso8601String();
    await db.update('user_profile', fields);
  }

  static Future<void> delete() async {
    final db = await _db.database;
    await db.delete('user_profile');
  }
}
