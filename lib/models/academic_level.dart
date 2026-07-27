class AcademicLevel {
  final int id;
  final String name;

  AcademicLevel({required this.id, required this.name});

  factory AcademicLevel.fromJson(Map<String, dynamic> json) {
    return AcademicLevel(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  // TODO: implement toMap/fromMap for SQLite
  Map<String, dynamic> toMap() => toJson();

  @override
  String toString() => name;
}
