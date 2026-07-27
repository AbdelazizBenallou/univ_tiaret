import 'academic_level.dart';
import 'academic_speciality.dart';

class AcademicProgram {
  final int id;
  final String name;
  final List<AcademicLevel> levels;
  final List<AcademicSpeciality> specialities;

  AcademicProgram({
    required this.id,
    required this.name,
    required this.levels,
    required this.specialities,
  });

  factory AcademicProgram.fromJson(Map<String, dynamic> json) {
    return AcademicProgram(
      id: json['id'] as int,
      name: json['name'] as String,
      levels: (json['levels'] as List? ?? [])
          .map((e) => AcademicLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
      specialities: (json['specialities'] as List? ?? [])
          .map((e) => AcademicSpeciality.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'levels': levels.map((e) => e.toJson()).toList(),
        'specialities': specialities.map((e) => e.toJson()).toList(),
      };

  // TODO: implement toMap/fromMap for SQLite
  Map<String, dynamic> toMap() => toJson();

  bool get hasSpecialities => specialities.isNotEmpty;

  @override
  String toString() => name;
}
