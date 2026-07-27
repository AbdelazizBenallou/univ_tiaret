import 'package:univ_tiaret/models/activity.dart';

class ActivityResponse {
  final int moduleId;
  final String moduleName;
  final List<Activity> activities;

  ActivityResponse({
    required this.moduleId,
    required this.moduleName,
    required this.activities,
  });

  factory ActivityResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final components = data['components'] as List;
    return ActivityResponse(
      moduleId: data['module_id'] as int,
      moduleName: data['module_name'] as String,
      activities: components
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
