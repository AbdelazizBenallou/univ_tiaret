import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/db_helper.dart';
import 'package:univ_tiaret/models/favorite_file.dart';

final favoriteProvider = ChangeNotifierProvider<FavoriteProvider>((ref) => FavoriteProvider());

class FavoriteProvider extends ChangeNotifier {
  List<FavoriteFile> _favorites = [];
  bool _initialized = false;

  List<FavoriteFile> get favorites => _favorites;
  bool get hasFavorites => _favorites.isNotEmpty;

  Set<int> get favoritedFileIds => _favorites.map((f) => f.fileId).toSet();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _load();
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
