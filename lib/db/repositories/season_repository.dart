import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/season.dart';

class SeasonRepository {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<void> insertAll(List<Season> seasons) async {
    final db = await _db.database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    batch.delete('cached_seasons');

    for (final season in seasons) {
      batch.insert('cached_seasons', {
        'id': season.id,
        'name': season.name,
        'is_current': season.isCurrent ? 1 : 0,
        'cached_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  static Future<List<Season>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('cached_seasons', orderBy: 'id DESC');
    return rows.map((row) => Season(
      id: row['id'] as int,
      name: row['name'] as String,
      isCurrent: (row['is_current'] as int) == 1,
    )).toList();
  }

  static Future<void> clear() async {
    final db = await _db.database;
    await db.delete('cached_seasons');
  }

  static Future<String?> getLastUpdateTime() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT cached_at FROM cached_seasons ORDER BY cached_at DESC LIMIT 1',
    );
    if (result.isEmpty) return null;
    return result.first['cached_at'] as String;
  }
}
