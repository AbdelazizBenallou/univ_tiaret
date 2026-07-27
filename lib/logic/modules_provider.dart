import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/models/module.dart';
import 'package:univ_tiaret/services/api_service.dart';

final modulesProvider =
    ChangeNotifierProvider<ModulesProvider>((ref) => ModulesProvider());

class ModulesProvider extends ChangeNotifier {
  List<Module> _modules = [];
  bool _loading = false;
  String? _error;

  List<Module> get modules => _modules;
  bool get loading => _loading;
  String? get error => _error;

  bool _isMaster(String? levelName) {
    if (levelName == null) return false;
    return levelName.toUpperCase().startsWith('M');
  }

  Future<void> fetchModules({
    required int semesterId,
    required String? levelName,
    int? specialityId,
  }) async {
    _loading = true;
    _error = null;
    _modules = [];
    notifyListeners();

    try {
      final isMaster = _isMaster(levelName);

      if (isMaster && specialityId == null) {
        _error = 'err_speciality_required';
        _loading = false;
        notifyListeners();
        return;
      }

      String endpoint;

      if (isMaster) {
        endpoint = '/v1/modules/master?semester_id=$semesterId&speciality_id=$specialityId';
      } else {
        endpoint = '/v1/modules/license?semester_id=$semesterId';
      }

      final response = await ApiService.get(endpoint);

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _modules = data
              .map((e) => Module.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = 'err_network';
    }

    _loading = false;
    notifyListeners();
  }
}
