import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/utils/file_utils.dart';

class OfficeViewer extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String fileType;

  const OfficeViewer({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileType,
  });

  @override
  State<OfficeViewer> createState() => _OfficeViewerState();
}

class _OfficeViewerState extends State<OfficeViewer> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = widget.fileType.toLowerCase();

    if (t == 'docx' || t == 'doc') {
      return _buildDocxViewer(isDark);
    }

    return _buildExternalViewer(isDark);
  }

  Widget _buildDocxViewer(bool isDark) {
    final file = File(widget.filePath);
    if (!file.existsSync()) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(widget.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: Center(child: Text('File not found')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(widget.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: DocxView(
        file: file,
        config: DocxViewConfig(
          theme: isDark ? DocxViewTheme.dark() : DocxViewTheme.light(),
        ),
      ),
    );
  }

  Widget _buildExternalViewer(bool isDark) {
    return _ExternalOpenViewer(
      filePath: widget.filePath,
      fileName: widget.fileName,
      fileType: widget.fileType,
      isDark: isDark,
    );
  }
}

class _ExternalOpenViewer extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String fileType;
  final bool isDark;

  const _ExternalOpenViewer({
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.isDark,
  });

  @override
  State<_ExternalOpenViewer> createState() => _ExternalOpenViewerState();
}

class _ExternalOpenViewerState extends State<_ExternalOpenViewer> {
  bool _opening = false;
  String? _error;

  Future<void> _openWithApp() async {
    setState(() {
      _opening = true;
      _error = null;
    });

    try {
      final result = await OpenFilex.open(widget.filePath);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        setState(() => _error = result.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to open file: $e');
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          widget.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: fileColor(widget.fileType).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  fileIcon(widget.fileType),
                  size: 40,
                  color: fileColor(widget.fileType),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.fileName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.fileType.toUpperCase()} ${_getSizeString()}',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(fontSize: 13, color: colors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              FilledButton.icon(
                onPressed: _opening ? null : _openWithApp,
                icon: _opening
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.open_in_new_rounded, size: 20),
                label: Text(_opening ? 'Opening...' : 'Open with...'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.greenAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Opens in an external app',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSizeString() {
    try {
      final file = File(widget.filePath);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {}
    return '';
  }
}
