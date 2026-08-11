import 'package:sqflite/sqflite.dart';
import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/current_subscription.dart';

class SubscriptionRepository {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<void> replaceAll({
    required int userId,
    required List<CurrentSubscription> subs,
  }) async {
    final db = await _db.database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    batch.delete('subscriptions', where: 'user_id = ?', whereArgs: [userId]);

    for (final sub in subs) {
      batch.insert(
        'subscriptions',
        _toRow(sub, userId: userId, cachedAt: now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<void> upsert(CurrentSubscription sub, {required int userId}) async {
    final db = await _db.database;
    await db.insert(
      'subscriptions',
      _toRow(sub, userId: userId, cachedAt: DateTime.now().toIso8601String()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<CurrentSubscription?> getActive({required int userId}) async {
    final db = await _db.database;
    final rows = await db.query(
      'subscriptions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );

    final now = DateTime.now();
    for (final row in rows) {
      final endDate = _parse(row['end_date']);
      if (endDate != null && endDate.isBefore(now)) continue;
      return _fromRow(row);
    }
    return null;
  }

  static Future<List<CurrentSubscription>> getAll({required int userId}) async {
    final db = await _db.database;
    final rows = await db.query(
      'subscriptions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(_fromRow).toList();
  }

  static Future<void> clear() async {
    final db = await _db.database;
    await db.delete('subscriptions');
  }

  static Map<String, dynamic> _toRow(
    CurrentSubscription sub, {
    required int userId,
    required String cachedAt,
  }) {
    return {
      'id': sub.id,
      'user_id': userId,
      'type': sub.type,
      'status': sub.status,
      'semester_id': sub.semesterId,
      'semester_name': sub.semesterName,
      'semester_start_date': sub.semesterStartDate?.toIso8601String(),
      'semester_end_date': sub.semesterEndDate?.toIso8601String(),
      'speciality_id': sub.specialityId,
      'speciality_name': sub.specialityName,
      'speciality_code': sub.specialityCode,
      'start_date': sub.startDate?.toIso8601String(),
      'end_date': sub.endDate?.toIso8601String(),
      'remaining_days': sub.remainingDays,
      'cached_at': cachedAt,
    };
  }

  static CurrentSubscription _fromRow(Map<String, dynamic> row) {
    return CurrentSubscription(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      semesterName: row['semester_name'] as String? ?? '',
      semesterId: row['semester_id'] as int? ?? 0,
      semesterStartDate: _parse(row['semester_start_date']),
      semesterEndDate: _parse(row['semester_end_date']),
      type: row['type'] as String? ?? '',
      status: row['status'] as String? ?? '',
      specialityId: row['speciality_id'] as int?,
      specialityName: row['speciality_name'] as String?,
      specialityCode: row['speciality_code'] as String?,
      startDate: _parse(row['start_date']),
      endDate: _parse(row['end_date']),
      remainingDays: row['remaining_days'] as int?,
    );
  }

  static DateTime? _parse(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }
}
