import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadStatus { queued, downloading, completed, failed, cancelled }

class DownloadItem {
  final int id;
  final String name;
  final String fileType;
  final String downloadUrl;
  final String seasonName;
  final String semesterName;
  final String moduleName;
  final String activityName;
  double progress;
  double speed;
  DownloadStatus status;
  String? localPath;
  String? error;
  DateTime? startedAt;
  DateTime? completedAt;

  DownloadItem({
    required this.id,
    required this.name,
    required this.fileType,
    required this.downloadUrl,
    this.seasonName = '',
    this.semesterName = '',
    this.moduleName = '',
    this.activityName = '',
    this.progress = 0,
    this.speed = 0,
    this.status = DownloadStatus.queued,
    this.localPath,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fileType': fileType,
    'downloadUrl': downloadUrl,
    'seasonName': seasonName,
    'semesterName': semesterName,
    'moduleName': moduleName,
    'activityName': activityName,
    'localPath': localPath,
  };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
    id: json['id'] as int,
    name: json['name'] as String,
    fileType: json['fileType'] as String,
    downloadUrl: json['downloadUrl'] as String,
    seasonName: json['seasonName'] as String? ?? '',
    semesterName: json['semesterName'] as String? ?? '',
    moduleName: json['moduleName'] as String? ?? '',
    activityName: json['activityName'] as String? ?? '',
    status: DownloadStatus.completed,
    localPath: json['localPath'] as String?,
  );

  String get speedFormatted {
    if (speed < 1024) return '${speed.toStringAsFixed(0)} B/s';
    if (speed < 1048576) return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    return '${(speed / 1048576).toStringAsFixed(1)} MB/s';
  }

  String get progressFormatted => '${(progress * 100).toStringAsFixed(0)}%';

  String get folderPath {
    final parts = [seasonName, semesterName, moduleName, activityName]
        .where((s) => s.isNotEmpty);
    return parts.join(' / ');
  }
}

typedef DownloadProgressCallback = void Function(DownloadItem item);

class DownloadService {
  static const int maxConcurrent = 3;
  static const String _storageKey = 'completed_downloads';
  static final List<DownloadItem> _queue = [];
  static final List<DownloadItem> _active = [];
  static final List<DownloadItem> _completed = [];
  static int _activeCount = 0;
  static DownloadProgressCallback? _onProgress;
  static DownloadProgressCallback? _onStatusChange;
  static Directory? _downloadDir;
  static bool _loaded = false;

  static List<DownloadItem> get queue => List.unmodifiable(_queue);
  static List<DownloadItem> get active => List.unmodifiable(_active);
  static List<DownloadItem> get completed => List.unmodifiable(_completed);
  static List<DownloadItem> get all =>
      [..._completed, ..._active, ..._queue];

  static void setCallbacks({
    DownloadProgressCallback? onProgress,
    DownloadProgressCallback? onStatusChange,
  }) {
    _onProgress = onProgress;
    _onStatusChange = onStatusChange;
  }

  static Future<void> loadCompleted() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json == null) return;
      final List<dynamic> list = jsonDecode(json);
      for (final entry in list) {
        final item = DownloadItem.fromJson(entry as Map<String, dynamic>);
        if (item.localPath != null) {
          final file = File(item.localPath!);
          if (await file.exists()) {
            _completed.add(item);
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> _saveCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _completed.map((i) => i.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {}
  }

  static Future<Directory> _getDownloadDir() async {
    if (_downloadDir != null) return _downloadDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _downloadDir = Directory('${appDir.path}/downloads');
    if (!await _downloadDir!.exists()) {
      await _downloadDir!.create(recursive: true);
    }
    return _downloadDir!;
  }

  static String _sanitizeDirName(String name) {
    return name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _extensionForType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return '.pdf';
      case 'doc': return '.doc';
      case 'docx': return '.docx';
      case 'ppt': return '.ppt';
      case 'pptx': return '.pptx';
      case 'xls': return '.xls';
      case 'xlsx': return '.xlsx';
      case 'jpg': case 'jpeg': return '.jpg';
      case 'png': return '.png';
      default: return '.$type';
    }
  }

  static Future<String> download({
    required int id,
    required String name,
    required String fileType,
    required String downloadUrl,
    String seasonName = '',
    String semesterName = '',
    String moduleName = '',
    String activityName = '',
  }) async {
    final existing = _queue.firstWhere(
      (item) => item.id == id,
      orElse: () => _active.firstWhere(
        (item) => item.id == id,
        orElse: () => _completed.firstWhere(
          (item) => item.id == id,
          orElse: () => DownloadItem(
            id: -1,
            name: '',
            fileType: '',
            downloadUrl: '',
          ),
        ),
      ),
    );
    if (existing.id == id &&
        (existing.status == DownloadStatus.downloading ||
            existing.status == DownloadStatus.queued)) {
      return 'already_in_queue';
    }

    final item = DownloadItem(
      id: id,
      name: name,
      fileType: fileType,
      downloadUrl: downloadUrl,
      seasonName: seasonName,
      semesterName: semesterName,
      moduleName: moduleName,
      activityName: activityName,
    );

    _queue.add(item);
    _onStatusChange?.call(item);
    _processQueue();
    return 'queued';
  }

  static void _processQueue() {
    while (_activeCount < maxConcurrent && _queue.isNotEmpty) {
      final item = _queue.removeAt(0);
      _active.add(item);
      _activeCount++;
      _startDownload(item);
    }
  }

  static final Map<int, http.Client> _clients = {};

  static Future<void> _startDownload(DownloadItem item) async {
    item.status = DownloadStatus.downloading;
    item.startedAt = DateTime.now();
    _onStatusChange?.call(item);

    final client = http.Client();
    _clients[item.id] = client;

    try {
      final dir = await _getDownloadDir();

      final parts = [
        item.seasonName,
        item.semesterName,
        item.moduleName,
        item.activityName,
      ].where((s) => s.isNotEmpty).map(_sanitizeDirName).toList();

      var targetDir = dir;
      for (final part in parts) {
        targetDir = Directory('${targetDir.path}/$part');
      }
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final safeName = item.name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
      final ext = _extensionForType(item.fileType);
      final file = File('${targetDir.path}/$safeName$ext');

      final request = http.Request('GET', Uri.parse(item.downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final sink = file.openWrite();

      int received = 0;
      int lastNotifyMs = DateTime.now().millisecondsSinceEpoch;
      int lastNotifyBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;

        if (contentLength > 0) {
          item.progress = received / contentLength;
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastNotifyMs >= 100 || item.progress >= 1.0) {
          final elapsed = now - lastNotifyMs;
          if (elapsed > 0) {
            item.speed = ((received - lastNotifyBytes) / elapsed) * 1000;
          }
          lastNotifyBytes = received;
          lastNotifyMs = now;
          _onProgress?.call(item);
        }
      }
      await sink.close();

      item.progress = 1.0;
      item.speed = 0;
      item.localPath = file.path;
      item.status = DownloadStatus.completed;
      item.completedAt = DateTime.now();
      _onStatusChange?.call(item);
    } catch (e) {
      item.status = DownloadStatus.failed;
      item.error = e.toString();
      _onStatusChange?.call(item);
    } finally {
      client.close();
      _clients.remove(item.id);
      _active.remove(item);
      if (item.status == DownloadStatus.completed) {
        _completed.insert(0, item);
        _saveCompleted();
      }
      _activeCount--;
      _processQueue();
    }
  }

  static void cancel(int id) {
    final client = _clients.remove(id);
    client?.close();
    final item = _queue.firstWhere(
      (i) => i.id == id,
      orElse: () => DownloadItem(id: -1, name: '', fileType: '', downloadUrl: ''),
    );
    if (item.id == id) {
      _queue.remove(item);
      item.status = DownloadStatus.cancelled;
      _onStatusChange?.call(item);
    } else {
      final activeItem = _active.firstWhere(
        (i) => i.id == id,
        orElse: () => DownloadItem(id: -1, name: '', fileType: '', downloadUrl: ''),
      );
      if (activeItem.id == id) {
        activeItem.status = DownloadStatus.cancelled;
        activeItem.error = 'Cancelled';
        _onStatusChange?.call(activeItem);
      }
    }
  }

  static Future<void> deleteDownload(int id) async {
    final item = _completed.firstWhere(
      (i) => i.id == id,
      orElse: () => DownloadItem(id: -1, name: '', fileType: '', downloadUrl: ''),
    );
    if (item.id == id && item.localPath != null) {
      final file = File(item.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _completed.remove(item);
      _saveCompleted();
    }
  }

  static bool isDownloaded(int id) {
    return _completed.any((item) => item.id == id);
  }

  static bool isActive(int id) {
    return _active.any((item) => item.id == id) ||
        _queue.any((item) => item.id == id);
  }

  static String? getLocalPath(int id) {
    final item = _completed.firstWhere(
      (i) => i.id == id,
      orElse: () => DownloadItem(id: -1, name: '', fileType: '', downloadUrl: ''),
    );
    return item.id == id ? item.localPath : null;
  }
}
