class SubscriptionDemand {
  final int id;
  final int userId;
  final int semesterId;
  final String semesterName;
  final String type;
  final String status;
  final int? specialityId;
  final String? specialityName;
  final String? specialityCode;
  final int? adminId;
  final String? adminEmail;
  final String? adminNote;
  final DateTime requestedAt;
  final DateTime? processedAt;

  SubscriptionDemand({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.semesterName,
    required this.type,
    required this.status,
    this.specialityId,
    this.specialityName,
    this.specialityCode,
    this.adminId,
    this.adminEmail,
    this.adminNote,
    required this.requestedAt,
    this.processedAt,
  });

  factory SubscriptionDemand.fromJson(Map<String, dynamic> json) {
    final semester = json['semester'] as Map<String, dynamic>?;
    final speciality = json['speciality'] as Map<String, dynamic>?;
    final admin = json['admin'] as Map<String, dynamic>?;
    return SubscriptionDemand(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      semesterId: semester?['id'] as int? ?? 0,
      semesterName: semester?['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      specialityId: speciality?['id'] as int?,
      specialityName: speciality?['name'] as String?,
      specialityCode: speciality?['code'] as String?,
      adminId: admin?['id'] as int?,
      adminEmail: admin?['email'] as String?,
      adminNote: json['admin_note'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'] as String)
          : null,
    );
  }
}
