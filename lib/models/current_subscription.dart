class CurrentSubscription {
  final int id;
  final int userId;
  final String semesterName;
  final int semesterId;
  final DateTime? semesterStartDate;
  final DateTime? semesterEndDate;
  final String type;
  final String status;
  final int? specialityId;
  final String? specialityName;
  final String? specialityCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? remainingDays;

  CurrentSubscription({
    required this.id,
    required this.userId,
    required this.semesterName,
    required this.semesterId,
    this.semesterStartDate,
    this.semesterEndDate,
    required this.type,
    required this.status,
    this.specialityId,
    this.specialityName,
    this.specialityCode,
    this.startDate,
    this.endDate,
    this.remainingDays,
  });

  factory CurrentSubscription.fromJson(Map<String, dynamic> json) {
    final semester = json['semester'] as Map<String, dynamic>?;
    final speciality = json['speciality'] as Map<String, dynamic>?;
    return CurrentSubscription(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      semesterName: semester?['name'] as String? ?? '',
      semesterId: semester?['id'] as int? ?? 0,
      semesterStartDate: semester?['start_date'] != null
          ? DateTime.tryParse(semester!['start_date'] as String)
          : null,
      semesterEndDate: semester?['end_date'] != null
          ? DateTime.tryParse(semester!['end_date'] as String)
          : null,
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      specialityId: speciality?['id'] as int?,
      specialityName: speciality?['name'] as String?,
      specialityCode: speciality?['code'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      remainingDays: json['remaining_days'] as int?,
    );
  }
}
