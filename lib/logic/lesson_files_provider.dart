import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/models/lesson_file.dart';
import 'package:univ_tiaret/services/api_service.dart';

enum LessonFilesStatus { initial, loading, loaded, error, noSubscription }

class LessonFilesState {
  final LessonFilesStatus status;
  final List<LessonFile> files;
  final String? error;
  final int page;
  final int totalPages;
  final int total;

  LessonFilesState({
    this.status = LessonFilesStatus.initial,
    this.files = const [],
    this.error,
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
  });

  LessonFilesState copyWith({
    LessonFilesStatus? status,
    List<LessonFile>? files,
    String? error,
    int? page,
    int? totalPages,
    int? total,
  }) {
    return LessonFilesState(
      status: status ?? this.status,
      files: files ?? this.files,
      error: error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
    );
  }
}

final lessonFilesProvider =
    ChangeNotifierProvider<LessonFilesProvider>((ref) => LessonFilesProvider());

class LessonFilesProvider extends ChangeNotifier {
  LessonFilesState _state = LessonFilesState();
  LessonFilesState get state => _state;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<void> fetchFiles({
    required int moduleId,
    required int activityTypeId,
    required int seasonId,
    int page = 1,
  }) async {
    if (page > 1) {
      if (_isLoadingMore) return;
      _isLoadingMore = true;
    }

    _state = _state.copyWith(
      status: page == 1 ? LessonFilesStatus.loading : LessonFilesStatus.loaded,
      files: page == 1 ? [] : _state.files,
    );
    notifyListeners();

    try {
      final endpoint =
          '/v1/lesson-files?module_id=$moduleId&activity_type_id=$activityTypeId&season_id=$seasonId&page=$page';

      final response = await ApiService.get(endpoint);

      if (response['success'] == true) {
        final data = response['data'];

        List<dynamic> fileList = [];
        int currentPage = page;
        int totalPages = 1;
        int total = 0;

        if (data is List) {
          fileList = data;
        } else if (data is Map<String, dynamic>) {
          fileList = data['data'] as List? ??
              data['files'] as List? ??
              data['items'] as List? ??
              [];
          final pag = data['pagination'] as Map<String, dynamic>?;
          if (pag != null) {
            currentPage = _toInt(pag['page'] ?? pag['current_page']) ?? page;
            totalPages =
                _toInt(pag['totalPages'] ?? pag['total_pages'] ?? pag['last_page'] ?? pag['lastPage']) ?? 1;
            total = _toInt(pag['total'] ?? pag['count']) ?? 0;
          }
        }

        final newFiles = fileList
            .map((e) => LessonFile.fromJson(e as Map<String, dynamic>))
            .toList();

        final allFiles = page == 1 ? newFiles : [..._state.files, ...newFiles];

        _state = _state.copyWith(
          status: LessonFilesStatus.loaded,
          files: allFiles,
          page: currentPage,
          totalPages: totalPages,
          total: total,
        );
      } else {
        final message = response['message'] ?? '';
        final msgLower = message.toLowerCase();

        if (msgLower.contains('no active subscription') ||
            msgLower.contains('subscription')) {
          _state = _state.copyWith(
            status: LessonFilesStatus.noSubscription,
            error: message,
          );
        } else {
          _state = _state.copyWith(
            status: LessonFilesStatus.error,
            error: message,
          );
        }
      }
    } catch (e) {
      _state = _state.copyWith(
        status: LessonFilesStatus.error,
        error: 'err_network',
      );
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadNextPage({
    required int moduleId,
    required int activityTypeId,
    required int seasonId,
  }) async {
    if (_isLoadingMore) return;
    if (_state.page >= _state.totalPages) return;
    await fetchFiles(
      moduleId: moduleId,
      activityTypeId: activityTypeId,
      seasonId: seasonId,
      page: _state.page + 1,
    );
  }

  void reset() {
    _state = LessonFilesState();
    _isLoadingMore = false;
    notifyListeners();
  }
}
