class SemesterRef {
  final int id;
  final String name;

  SemesterRef({required this.id, required this.name});

  factory SemesterRef.fromJson(Map<String, dynamic> json) {
    return SemesterRef(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class Module {
  final int id;
  final String name;
  final String code;
  final String coefficient;
  final int credit;
  final SemesterRef semester;

  Module({
    required this.id,
    required this.name,
    required this.code,
    required this.coefficient,
    required this.credit,
    required this.semester,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      coefficient: '${json['coefficient']}',
      credit: json['credit'] as int,
      semester: SemesterRef.fromJson(json['semesters'] as Map<String, dynamic>),
    );
  }
}
