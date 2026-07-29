import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/lesson_file.dart';

class LessonFileRepository {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<void> insertAll(List<LessonFile> files, {bool append = false}) async {
    if (files.isEmpty) return;
    final db = await _db.database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    final first = files.first;

    if (!append) {
      batch.delete(
        'cached_lesson_files',
        where: 'module_id = ? AND activity_type_id = ? AND season_id = ?',
        whereArgs: [first.moduleId, first.activityTypeId, first.seasonId],
      );
    }

    for (final file in files) {
      batch.insert('cached_lesson_files', {
        'id': file.id,
        'name': file.name,
        'description': file.description,
        'url': file.url,
        'file_type': file.fileType,
        'module_id': file.moduleId,
        'activity_type_id': file.activityTypeId,
        'activity_type': file.activityType,
        'season_id': file.seasonId,
        'uploaded_at': file.uploadedAt,
        'cached_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  static Future<List<LessonFile>> getByFilter({
    required int moduleId,
    required int activityTypeId,
    required int seasonId,
    String? searchQuery,
  }) async {
    final db = await _db.database;
    final where = 'module_id = ? AND activity_type_id = ? AND season_id = ?';
    final whereArgs = <dynamic>[moduleId, activityTypeId, seasonId];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      whereArgs.addAll([q, q]);
    }

    final rows = await db.query(
      'cached_lesson_files',
      where: searchQuery != null && searchQuery.isNotEmpty
          ? '$where AND (name LIKE ? OR description LIKE ?)'
          : where,
      whereArgs: whereArgs,
      orderBy: 'uploaded_at DESC',
    );

    return rows.map((row) => LessonFile(
      id: row['id'] as int,
      name: row['name'] as String,
      description: row['description'] as String,
      url: row['url'] as String,
      fileType: row['file_type'] as String,
      moduleId: row['module_id'] as int,
      activityTypeId: row['activity_type_id'] as int,
      activityType: row['activity_type'] as String,
      seasonId: row['season_id'] as int,
      uploadedAt: row['uploaded_at'] as String,
    )).toList();
  }

  static Future<void> clearByFilter({
    required int moduleId,
    required int activityTypeId,
    required int seasonId,
  }) async {
    final db = await _db.database;
    await db.delete(
      'cached_lesson_files',
      where: 'module_id = ? AND activity_type_id = ? AND season_id = ?',
      whereArgs: [moduleId, activityTypeId, seasonId],
    );
  }
}
