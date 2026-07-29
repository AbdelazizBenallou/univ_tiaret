import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/db.dart';
import 'package:univ_tiaret/models/lesson_file.dart';
import 'package:univ_tiaret/services/api_service.dart';

enum LessonFilesStatus { initial, loading, loaded, loadingMore, error, noSubscription }

class LessonFilesState {
  final LessonFilesStatus status;
  final List<LessonFile> files;
  final String? error;
  final int page;
  final int totalPages;
  final int total;
  final bool fromCache;

  LessonFilesState({
    this.status = LessonFilesStatus.initial,
    this.files = const [],
    this.error,
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.fromCache = false,
  });

  LessonFilesState copyWith({
    LessonFilesStatus? status,
    List<LessonFile>? files,
    String? error,
    int? page,
    int? totalPages,
    int? total,
    bool? fromCache,
  }) {
    return LessonFilesState(
      status: status ?? this.status,
      files: files ?? this.files,
      error: error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

final lessonFilesProvider =
    ChangeNotifierProvider<LessonFilesProvider>((ref) => LessonFilesProvider());

class LessonFilesProvider extends ChangeNotifier {
  LessonFilesState _state = LessonFilesState();
  LessonFilesState get state => _state;

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
    if (page == 1) {
      _state = _state.copyWith(status: LessonFilesStatus.loading);
      notifyListeners();

      final cached = await LessonFileRepository.getByFilter(
        moduleId: moduleId,
        activityTypeId: activityTypeId,
        seasonId: seasonId,
      );
      if (cached.isNotEmpty) {
        _state = _state.copyWith(
          status: LessonFilesStatus.loaded,
          files: cached,
          fromCache: true,
          page: 1,
          error: null,
        );
        notifyListeners();
      }
    } else {
      _state = _state.copyWith(status: LessonFilesStatus.loadingMore);
      notifyListeners();
    }

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

        if (newFiles.isNotEmpty) {
          await LessonFileRepository.insertAll(newFiles, append: page > 1);
        }

        _state = _state.copyWith(
          status: LessonFilesStatus.loaded,
          files: allFiles,
          page: currentPage,
          totalPages: totalPages,
          total: total,
          fromCache: false,
        );
      } else {
        final message = response['message'] ?? '';
        final msgLower = message.toLowerCase();

        if (msgLower.contains('no active subscription') ||
            msgLower.contains('subscription')) {
          _state = _state.copyWith(
            status: LessonFilesStatus.noSubscription,
            error: 'err_no_subscription',
          );
        } else if (_state.files.isEmpty) {
          _state = _state.copyWith(
            status: LessonFilesStatus.error,
            error: 'err_server_error',
          );
        } else {
          _state = _state.copyWith(
            status: LessonFilesStatus.loaded,
            page: 1,
            totalPages: 1,
          );
        }
      }
    } catch (e) {
      if (_state.files.isEmpty) {
        _state = _state.copyWith(
          status: LessonFilesStatus.error,
          error: 'err_network',
        );
      } else {
        _state = _state.copyWith(
          status: LessonFilesStatus.loaded,
          page: 1,
          totalPages: 1,
        );
      }
    }

    notifyListeners();
  }

  Future<void> loadNextPage({
    required int moduleId,
    required int activityTypeId,
    required int seasonId,
  }) async {
    if (_state.status == LessonFilesStatus.loadingMore) return;
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
    notifyListeners();
  }
}
