class UserModel {
  final int? id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? status;
  final List<String>? roles;
  final int? levelId;
  final String? levelName;
  final int? specialityId;
  final String? specialityName;
  final String? studentId;
  final String? phone;
  final String? avatar;

  UserModel({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.gender,
    this.status,
    this.roles,
    this.levelId,
    this.levelName,
    this.specialityId,
    this.specialityName,
    this.studentId,
    this.phone,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final level = profile?['level'] as Map<String, dynamic>?;
    final speciality = profile?['speciality'] as Map<String, dynamic>?;

    return UserModel(
      id: json['id'],
      email: json['email'],
      firstName: profile?['first_name'] ?? json['first_name'],
      lastName: profile?['last_name'] ?? json['last_name'],
      gender: profile?['gender'] ?? json['gender'],
      status: json['status'],
      roles: json['roles'] != null
          ? List<String>.from(json['roles'])
          : null,
      levelId: level?['id'] ?? json['level_id'],
      levelName: level?['name'] ?? json['level_name'],
      specialityId: speciality?['id'] ?? json['speciality_id'],
      specialityName: speciality?['name'] ?? json['speciality_name'],
      studentId: profile?['student_id'] ?? json['student_id'],
      phone: profile?['phone'] ?? json['phone'],
      avatar: profile?['avatar'] ?? json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'status': status,
      'roles': roles,
      'level_id': levelId,
      'level_name': levelName,
      'speciality_id': specialityId,
      'speciality_name': specialityName,
      'student_id': studentId,
      'phone': phone,
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? gender,
    String? phone,
    String? avatar,
    int? levelId,
    String? levelName,
    int? specialityId,
    String? specialityName,
  }) {
    return UserModel(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      status: status,
      roles: roles,
      levelId: levelId ?? this.levelId,
      levelName: levelName ?? this.levelName,
      specialityId: specialityId ?? this.specialityId,
      specialityName: specialityName ?? this.specialityName,
      studentId: studentId,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
    );
  }
}
