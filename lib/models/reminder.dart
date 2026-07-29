class Reminder {
  final int? id;
  final String title;
  final String description;
  final String dateTime;
  final String createdAt;

  Reminder({
    this.id,
    required this.title,
    this.description = '',
    required this.dateTime,
    this.createdAt = '',
  });

  factory Reminder.fromDb(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dateTime: map['date_time'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'title': title,
      'description': description,
      'date_time': dateTime,
      'created_at': createdAt,
    };
  }
}
