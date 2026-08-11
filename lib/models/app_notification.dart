class AppNotification {
  final int? id;
  final int? reminderId;
  final String title;
  final String body;
  final String firedAt;

  AppNotification({
    this.id,
    this.reminderId,
    required this.title,
    this.body = '',
    required this.firedAt,
  });

  factory AppNotification.fromDb(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int?,
      reminderId: map['reminder_id'] as int?,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      firedAt: map['fired_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'reminder_id': reminderId,
      'title': title,
      'body': body,
      'fired_at': firedAt,
    };
  }
}
