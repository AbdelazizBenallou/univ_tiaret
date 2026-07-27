class Semester {
  final int id;
  final String name;
  final int levelId;
  final bool isCurrent;
  final DateTime? startDate;
  final DateTime? endDate;

  Semester({
    required this.id,
    required this.name,
    required this.levelId,
    this.isCurrent = false,
    this.startDate,
    this.endDate,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as int,
      name: json['name'] as String,
      levelId: json['level_id'] as int,
      isCurrent: json['is_current'] as bool? ?? false,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
    );
  }

  @override
  String toString() => name;
}
