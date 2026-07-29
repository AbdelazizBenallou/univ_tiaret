import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/reminder.dart';

final reminderProvider = ChangeNotifierProvider<ReminderProvider>((ref) => ReminderProvider());

class ReminderProvider extends ChangeNotifier {
  List<Reminder> _reminders = [];
  bool _initialized = false;

  List<Reminder> get reminders => _reminders;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('reminders', orderBy: 'date_time ASC');
    _reminders = rows.map((r) => Reminder.fromDb(r)).toList();
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
