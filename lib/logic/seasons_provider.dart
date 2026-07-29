import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/db.dart';
import 'package:univ_tiaret/models/season.dart';
import 'package:univ_tiaret/services/api_service.dart';

final seasonsProvider = ChangeNotifierProvider<SeasonsProvider>((ref) {
  return SeasonsProvider();
});

class SeasonsProvider extends ChangeNotifier {
  List<Season> _seasons = [];
  bool _loading = false;
  String? _error;
  bool _fromCache = false;

  List<Season> get seasons => _seasons;
  bool get loading => _loading;
  String? get error => _error;
  bool get fromCache => _fromCache;

  Future<void> fetchSeasons() async {
    _loading = true;
    _error = null;
    notifyListeners();

    final cached = await SeasonRepository.getAll();
    if (cached.isNotEmpty) {
      _seasons = cached;
      _fromCache = true;
      _loading = false;
      notifyListeners();
    }

    try {
      final response = await ApiService.get('/v1/seasons');

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          final fresh = data
              .map((e) => Season.fromJson(e as Map<String, dynamic>))
              .toList()
              .reversed
              .toList();
          await SeasonRepository.insertAll(fresh);
          _seasons = fresh;
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
