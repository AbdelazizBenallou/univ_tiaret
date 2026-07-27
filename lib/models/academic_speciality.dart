class AcademicSpeciality {
  final int id;
  final String name;
  final String? code;

  AcademicSpeciality({required this.id, required this.name, this.code});

  factory AcademicSpeciality.fromJson(Map<String, dynamic> json) {
    return AcademicSpeciality(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};

  // TODO: implement toMap/fromMap for SQLite
  Map<String, dynamic> toMap() => toJson();

  @override
  String toString() => name;
}
