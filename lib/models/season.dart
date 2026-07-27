class Season {
  final int id;
  final String name;
  final bool isCurrent;

  Season({required this.id, required this.name, this.isCurrent = false});

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as int,
      name: json['name'] as String,
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_current': isCurrent,
      };

  @override
  String toString() => name;
}
