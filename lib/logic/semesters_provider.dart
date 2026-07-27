import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/models/semester.dart';
import 'package:univ_tiaret/services/api_service.dart';

final semestersProvider =
    ChangeNotifierProvider<SemestersProvider>((ref) => SemestersProvider());

class SemestersProvider extends ChangeNotifier {
  List<Semester> _semesters = [];
  bool _loading = false;
  String? _error;

  List<Semester> get semesters => _semesters;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchSemesters({required int levelId}) async {
    _loading = true;
    _error = null;
    _semesters = [];
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/v1/semesters?level_id=$levelId',
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _semesters = data
              .map((e) => Semester.fromJson(e as Map<String, dynamic>))
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
