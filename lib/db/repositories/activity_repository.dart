import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/activity.dart';

class ActivityRepository {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<void> insertAll(int moduleId, List<Activity> activities) async {
    final db = await _db.database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    batch.delete('cached_activities', where: 'module_id = ?', whereArgs: [moduleId]);

    for (final activity in activities) {
      batch.insert('cached_activities', {
        'id': activity.id,
        'name': activity.name,
        'module_id': moduleId,
        'cached_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  static Future<List<Activity>> getByModule(int moduleId) async {
    final db = await _db.database;
    final rows = await db.query(
      'cached_activities',
      where: 'module_id = ?',
      whereArgs: [moduleId],
    );
    return rows.map((row) => Activity(
      id: row['id'] as int,
      name: row['name'] as String,
    )).toList();
  }

  static Future<void> clearByModule(int moduleId) async {
    final db = await _db.database;
    await db.delete('cached_activities', where: 'module_id = ?', whereArgs: [moduleId]);
  }
}
