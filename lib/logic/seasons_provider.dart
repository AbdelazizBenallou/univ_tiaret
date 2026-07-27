import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/models/season.dart';
import 'package:univ_tiaret/services/api_service.dart';

final seasonsProvider = ChangeNotifierProvider<SeasonsProvider>((ref) {
  return SeasonsProvider();
});

class SeasonsProvider extends ChangeNotifier {
  List<Season> _seasons = [];
  bool _loading = false;
  String? _error;

  List<Season> get seasons => _seasons;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchSeasons() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/v1/seasons');

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _seasons = data
              .map((e) => Season.fromJson(e as Map<String, dynamic>))
              .toList()
              .reversed
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
