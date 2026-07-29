import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/semester.dart';

class SemesterRepository {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<void> insertAll(int levelId, List<Semester> semesters) async {
    final db = await _db.database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    batch.delete('cached_semesters', where: 'level_id = ?', whereArgs: [levelId]);

    for (final semester in semesters) {
      batch.insert('cached_semesters', {
        'id': semester.id,
        'name': semester.name,
        'level_id': levelId,
        'is_current': semester.isCurrent ? 1 : 0,
        'start_date': semester.startDate?.toIso8601String(),
        'end_date': semester.endDate?.toIso8601String(),
        'cached_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  static Future<List<Semester>> getByLevel(int levelId) async {
    final db = await _db.database;
    final rows = await db.query(
      'cached_semesters',
      where: 'level_id = ?',
      whereArgs: [levelId],
    );
    return rows.map((row) => Semester(
      id: row['id'] as int,
      name: row['name'] as String,
      levelId: row['level_id'] as int,
      isCurrent: (row['is_current'] as int) == 1,
      startDate: row['start_date'] != null
          ? DateTime.tryParse(row['start_date'] as String)
          : null,
      endDate: row['end_date'] != null
          ? DateTime.tryParse(row['end_date'] as String)
          : null,
    )).toList();
  }

  static Future<void> clearByLevel(int levelId) async {
    final db = await _db.database;
    await db.delete('cached_semesters', where: 'level_id = ?', whereArgs: [levelId]);
  }
}
