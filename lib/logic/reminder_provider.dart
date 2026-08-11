import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/reminder.dart';
import 'package:univ_tiaret/services/notification_service.dart';

final reminderProvider = ChangeNotifierProvider<ReminderProvider>((ref) => ReminderProvider());

class ReminderProvider extends ChangeNotifier {
  List<Reminder> _reminders = [];
  bool _initialized = false;

  List<Reminder> get reminders => _reminders;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _load();
    await _rescheduleAll();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('reminders', orderBy: 'date_time ASC');
    _reminders = rows.map((r) => Reminder.fromDb(r)).toList();
    notifyListeners();
  }

  /// Re-register scheduled notifications after app restart / boot.
  Future<void> _rescheduleAll() async {
    final now = DateTime.now();
    for (final r in _reminders) {
      final dt = DateTime.tryParse(r.dateTime);
      if (dt == null || !dt.isAfter(now)) continue;
      final id = r.id;
      if (id == null) continue;
      await NotificationService.instance.schedule(
        id: id,
        title: r.title,
        body: r.description.isEmpty ? 'Reminder' : r.description,
        dateTime: dt,
      );
    }
    await NotificationService.instance.refreshPendingCount();
  }

  Future<void> add(Reminder reminder) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('reminders', reminder.toDb());
    _reminders.add(Reminder(
      id: id,
      title: reminder.title,
      description: reminder.description,
      dateTime: reminder.dateTime,
      createdAt: reminder.createdAt,
    ));
    _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final dt = DateTime.tryParse(reminder.dateTime);
    if (dt != null && dt.isAfter(DateTime.now())) {
      await NotificationService.instance.schedule(
        id: id,
        title: reminder.title,
        body: reminder.description.isEmpty ? 'Reminder' : reminder.description,
        dateTime: dt,
      );
    }

    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    _reminders.removeWhere((r) => r.id == id);
    await NotificationService.instance.cancel(id);
    notifyListeners();
  }
}
