import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/services/download_service.dart';

final downloadProvider =
    ChangeNotifierProvider<DownloadProvider>((ref) => DownloadProvider());

class DownloadProvider extends ChangeNotifier {
  List<DownloadItem> _items = [];
  bool _initialized = false;
  bool _disposed = false;
  bool _notifyScheduled = false;
  bool _needsUpdate = false;
  Timer? _progressThrottle;

  List<DownloadItem> get items => _items;
  List<DownloadItem> get downloading =>
      _items.where((i) => i.status == DownloadStatus.downloading).toList();
  List<DownloadItem> get queued =>
      _items.where((i) => i.status == DownloadStatus.queued).toList();
  List<DownloadItem> get completed =>
      _items.where((i) => i.status == DownloadStatus.completed).toList();
  List<DownloadItem> get failed =>
      _items.where((i) => i.status == DownloadStatus.failed).toList();
  int get activeCount =>
      _items.where((i) =>
          i.status == DownloadStatus.downloading ||
          i.status == DownloadStatus.queued).length;

  bool isDownloaded(int id) => DownloadService.isDownloaded(id);
  bool isActive(int id) => DownloadService.isActive(id);

  void _forceNotify() {
    if (_disposed) return;
    _needsUpdate = true;
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    Timer(Duration.zero, () {
      _notifyScheduled = false;
      if (_disposed) return;
      if (_needsUpdate) {
        _needsUpdate = false;
        _items = DownloadService.all;
        notifyListeners();
      }
    });
  }

  void _throttledProgressNotify() {
    if (_disposed) return;
    _needsUpdate = true;
    if (_progressThrottle != null && _progressThrottle!.isActive) return;
    _progressThrottle = Timer(const Duration(milliseconds: 100), () {
      _forceNotify();
    });
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await DownloadService.loadCompleted();
    DownloadService.setCallbacks(
      onProgress: (item) {
        _throttledProgressNotify();
      },
      onStatusChange: (item) {
        if (_disposed) return;
        _forceNotify();
      },
    );
    _items = DownloadService.all;
    _forceNotify();
  }

  Future<void> downloadFile({
    required int id,
    required String name,
    required String fileType,
    required String downloadUrl,
    String seasonName = '',
    String semesterName = '',
    String moduleName = '',
    String activityName = '',
  }) async {
    await DownloadService.download(
      id: id,
      name: name,
      fileType: fileType,
      downloadUrl: downloadUrl,
      seasonName: seasonName,
      semesterName: semesterName,
      moduleName: moduleName,
      activityName: activityName,
    );
    _forceNotify();
  }

  void cancelDownload(int id) {
    DownloadService.cancel(id);
    _forceNotify();
  }

  Future<void> deleteDownload(int id) async {
    await DownloadService.deleteDownload(id);
    _forceNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _progressThrottle?.cancel();
    DownloadService.setCallbacks(onProgress: null, onStatusChange: null);
    super.dispose();
  }
}
