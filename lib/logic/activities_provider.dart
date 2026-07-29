import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/db.dart';
import 'package:univ_tiaret/models/activity.dart';
import 'package:univ_tiaret/services/api_service.dart';

final activitiesProvider =
    ChangeNotifierProvider<ActivitiesProvider>((ref) => ActivitiesProvider());

class ActivitiesProvider extends ChangeNotifier {
  List<Activity> _activities = [];
  String _moduleName = '';
  bool _loading = false;
  String? _error;
  bool _fromCache = false;

  List<Activity> get activities => _activities;
  String get moduleName => _moduleName;
  bool get loading => _loading;
  String? get error => _error;
  bool get fromCache => _fromCache;

  Future<void> fetchActivities({required int moduleId}) async {
    _loading = true;
    _error = null;
    _activities = [];
    notifyListeners();

    final cached = await ActivityRepository.getByModule(moduleId);
    if (cached.isNotEmpty) {
      _activities = cached;
      _fromCache = true;
      _loading = false;
      notifyListeners();
    }

    try {
      final response = await ApiService.get(
        '/v1/modules/$moduleId/components',
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          _moduleName = data['module_name'] as String? ?? '';
          final components = data['components'] as List?;
          if (components != null) {
            final fresh = components
                .map((e) => Activity.fromJson(e as Map<String, dynamic>))
                .toList();
            await ActivityRepository.insertAll(moduleId, fresh);
            _activities = fresh;
            _fromCache = false;
            _error = null;
          }
        }
      } else {
        if (cached.isEmpty) {
          _error = 'err_server_error';
        }
      }
    } catch (_) {
      if (cached.isEmpty) {
        _error = 'err_network';
      }
    }

    _loading = false;
    notifyListeners();
  }
}
