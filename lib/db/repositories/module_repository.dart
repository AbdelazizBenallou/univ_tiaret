import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/module.dart';

class ModuleRepository {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<void> insertAll({
    required int semesterId,
    required String? levelName,
    int? specialityId,
    required List<Module> modules,
  }) async {
    final db = await _db.database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    batch.delete(
      'cached_modules',
      where: 'semester_id = ? AND level_name = ? AND speciality_id IS ?',
      whereArgs: [semesterId, levelName, specialityId],
    );

    for (final module in modules) {
      batch.insert('cached_modules', {
        'id': module.id,
        'name': module.name,
        'code': module.code,
        'coefficient': module.coefficient,
        'credit': module.credit,
        'semester_id': semesterId,
        'speciality_id': specialityId,
        'level_name': levelName,
        'cached_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  static Future<List<Module>> getBySemester({
    required int semesterId,
    required String? levelName,
    int? specialityId,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'cached_modules',
      where: 'semester_id = ? AND level_name = ? AND speciality_id IS ?',
      whereArgs: [semesterId, levelName, specialityId],
    );
    return rows.map((row) {
      return Module(
        id: row['id'] as int,
        name: row['name'] as String,
        code: row['code'] as String,
        coefficient: row['coefficient'] as String,
        credit: row['credit'] as int,
        semester: SemesterRef(id: semesterId, name: ''),
      );
    }).toList();
  }

  static Future<void> clearBySemester(int semesterId) async {
    final db = await _db.database;
    await db.delete('cached_modules', where: 'semester_id = ?', whereArgs: [semesterId]);
  }
}
