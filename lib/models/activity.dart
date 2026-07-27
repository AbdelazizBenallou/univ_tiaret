class Activity {
  final int id;
  final String name;

  Activity({required this.id, required this.name});

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
