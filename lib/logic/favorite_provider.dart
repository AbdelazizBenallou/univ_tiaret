import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/favorite_file.dart';

final favoriteProvider = ChangeNotifierProvider<FavoriteProvider>((ref) => FavoriteProvider());

class FavoriteProvider extends ChangeNotifier {
  List<FavoriteFile> _favorites = [];
  bool _initialized = false;

  String _filterModule = '';
  String _filterActivity = '';
  String _filterSeason = '';

  static const _moduleKey = 'favorite_filter_module';
  static const _activityKey = 'favorite_filter_activity';
  static const _seasonKey = 'favorite_filter_season';

  List<FavoriteFile> get favorites => _favorites;
  bool get hasFavorites => _favorites.isNotEmpty;

  String get filterModule => _filterModule;
  String get filterActivity => _filterActivity;
  String get filterSeason => _filterSeason;

  bool get hasActiveFilter =>
      _filterModule.isNotEmpty || _filterActivity.isNotEmpty || _filterSeason.isNotEmpty;

  Set<int> get favoritedFileIds => _favorites.map((f) => f.fileId).toSet();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _loadFilters();
    await _load();
  }

  Future<void> _loadFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _filterModule = prefs.getString(_moduleKey) ?? '';
      _filterActivity = prefs.getString(_activityKey) ?? '';
      _filterSeason = prefs.getString(_seasonKey) ?? '';
    } catch (_) {}
  }

  Future<void> setFilter({
    String module = '',
    String activity = '',
    String season = '',
  }) async {
    _filterModule = module;
    _filterActivity = activity;
    _filterSeason = season;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_moduleKey, module);
      await prefs.setString(_activityKey, activity);
      await prefs.setString(_seasonKey, season);
    } catch (_) {}
    notifyListeners();
  }

  List<FavoriteFile> filteredFavorites() {
    var result = _favorites;
    if (_filterModule.isNotEmpty) {
      result = result.where((f) => f.moduleName == _filterModule).toList();
    }
    if (_filterActivity.isNotEmpty) {
      result = result.where((f) => f.activityName == _filterActivity).toList();
    }
    if (_filterSeason.isNotEmpty) {
      result = result.where((f) => f.seasonName == _filterSeason).toList();
    }
    return result;
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('favorites', orderBy: 'created_at DESC');
    _favorites = rows.map((r) => FavoriteFile.fromDb(r)).toList();
    notifyListeners();
  }

  bool isFavorited(int fileId) {
    return _favorites.any((f) => f.fileId == fileId);
  }

  Future<void> toggle(FavoriteFile fav) async {
    if (isFavorited(fav.fileId)) {
      await remove(fav.fileId);
    } else {
      await add(fav);
    }
  }

  Future<void> add(FavoriteFile fav) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('favorites', fav.toDb());
    _favorites.insert(0, fav);
    notifyListeners();
  }

  Future<void> remove(int fileId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('favorites', where: 'file_id = ?', whereArgs: [fileId]);
    _favorites.removeWhere((f) => f.fileId == fileId);
    notifyListeners();
  }
}
