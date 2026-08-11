import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/app_notification.dart';
import 'package:univ_tiaret/services/badge_service.dart';

final notificationHistoryProvider =
    ChangeNotifierProvider<NotificationHistoryProvider>(
  (ref) => NotificationHistoryProvider(),
);

class NotificationHistoryProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _initialized = false;

  List<AppNotification> get notifications => _notifications;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _load();
    await _captureFired();
    await _updateBadge();
  }

  /// Records reminders whose time has passed as fired notifications.
  Future<void> _captureFired() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final rows = await db.query('reminders');
    for (final row in rows) {
      final id = row['id'] as int?;
      final dateTime = DateTime.tryParse(row['date_time'] as String? ?? '');
      if (id == null || dateTime == null || dateTime.isAfter(now)) continue;

      final existing = await db.query(
        'notification_history',
        where: 'reminder_id = ?',
        whereArgs: [id],
      );
      if (existing.isNotEmpty) continue;

      await db.insert('notification_history', {
        'reminder_id': id,
        'title': row['title'],
        'body': row['description'] ?? '',
        'fired_at': row['date_time'],
      });
    }
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'notification_history',
      orderBy: 'fired_at DESC',
    );
    _notifications = rows.map((r) => AppNotification.fromDb(r)).toList();
    notifyListeners();
  }

  Future<void> _updateBadge() async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM notification_history'),
    );
    BadgeService.notificationCount.value = count ?? 0;
  }

  Future<void> clear() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('notification_history');
    await _load();
    await _updateBadge();
  }

  Future<void> refresh() async {
    await _captureFired();
    await _load();
    await _updateBadge();
  }
}
