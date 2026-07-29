import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/db.dart';
import 'package:univ_tiaret/models/semester.dart';
import 'package:univ_tiaret/services/api_service.dart';

final semestersProvider =
    ChangeNotifierProvider<SemestersProvider>((ref) => SemestersProvider());

class SemestersProvider extends ChangeNotifier {
  List<Semester> _semesters = [];
  bool _loading = false;
  String? _error;
  bool _fromCache = false;

  List<Semester> get semesters => _semesters;
  bool get loading => _loading;
  String? get error => _error;
  bool get fromCache => _fromCache;

  Future<void> fetchSemesters({required int levelId}) async {
    _loading = true;
    _error = null;
    _semesters = [];
    notifyListeners();

    final cached = await SemesterRepository.getByLevel(levelId);
    if (cached.isNotEmpty) {
      _semesters = cached;
      _fromCache = true;
      _loading = false;
      notifyListeners();
    }

    try {
      final response = await ApiService.get(
        '/v1/semesters?level_id=$levelId',
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          final fresh = data
              .map((e) => Semester.fromJson(e as Map<String, dynamic>))
              .toList();
          await SemesterRepository.insertAll(levelId, fresh);
          _semesters = fresh;
          _fromCache = false;
          _error = null;
        }
      } else {
        if (cached.isEmpty) {
          _error = 'err_server_error';
        }
      }
    } catch (e) {
      if (cached.isEmpty) {
        _error = 'err_network';
      }
    }

    _loading = false;
    notifyListeners();
  }
}
