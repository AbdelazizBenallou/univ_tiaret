import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:univ_tiaret/utils/file_utils.dart';
import 'package:univ_tiaret/screens/file_viewer/viewers/image_viewer.dart';
import 'package:univ_tiaret/screens/file_viewer/viewers/text_viewer.dart';
import 'package:univ_tiaret/screens/file_viewer/viewers/office_viewer.dart';
import 'package:univ_tiaret/screens/file_viewer/viewers/media_player_screen.dart';

class FileViewerScreen extends StatelessWidget {
  final String filePath;
  final String fileName;
  final String fileType;

  const FileViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileType,
  });

  @override
  Widget build(BuildContext context) {
    var category = fileCategory(fileType);

    if (category == FileCategory.unknown) {
      category = fileCategoryFromPath(filePath);
    }

    switch (category) {
      case FileCategory.pdf:
        return _PdfViewer(filePath: filePath, fileName: fileName);
      case FileCategory.image:
        return ImageViewer(filePath: filePath, fileName: fileName);
      case FileCategory.text:
        return TextViewer(
          filePath: filePath,
          fileName: fileName,
          fileType: fileType,
          isCode: false,
        );
      case FileCategory.code:
        return TextViewer(
          filePath: filePath,
          fileName: fileName,
          fileType: fileType,
          isCode: true,
        );
      case FileCategory.office:
        return OfficeViewer(
          filePath: filePath,
          fileName: fileName,
          fileType: fileType,
        );
      case FileCategory.video:
      case FileCategory.audio:
        return MediaPlayerScreen(
          filePath: filePath,
          fileName: fileName,
          fileType: fileType,
        );
      case FileCategory.unknown:
        return _UnsupportedViewer(
          filePath: filePath,
          fileName: fileName,
          fileType: fileType,
        );
    }
  }
}

class _PdfViewer extends StatefulWidget {
  final String filePath;
  final String fileName;

  const _PdfViewer({required this.filePath, required this.fileName});

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  bool _loading = true;
  String? _error;
  bool _darkMode = false;
  final PdfViewerController _controller = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  void _checkFile() {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) {
        setState(() {
          _error = 'File not found';
          _loading = false;
        });
        return;
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to open file: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: !_loading && _error == null
          ? AppBar(
              title: Text(
                widget.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                if (_totalPages > 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Text(
                        '$_currentPage/$_totalPages',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: _totalPages > 0 ? _showPageJumpDialog : null,
                  icon: Icon(Icons.tag_rounded, size: 22),
                  tooltip: 'Go to page',
                ),
                IconButton(
                  onPressed: () => setState(() => _darkMode = !_darkMode),
                  icon: Icon(
                    _darkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    size: 22,
                  ),
                  tooltip: _darkMode ? 'Light mode' : 'Dark mode',
                ),
                PopupMenuButton<String>(
                  onSelected: _onMenuAction,
                  icon: Icon(Icons.more_vert_rounded, size: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'zoom_in',
                        child: Row(
                          children: [
                            Icon(Icons.zoom_in_rounded, size: 20),
                            const SizedBox(width: 12),
                            const Text('Zoom in'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'zoom_out',
                        child: Row(
                          children: [
                            Icon(Icons.zoom_out_rounded, size: 20),
                            const SizedBox(width: 12),
                            const Text('Zoom out'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'fit_page',
                        child: Row(
                          children: [
                            Icon(Icons.fit_screen_rounded, size: 20),
                            const SizedBox(width: 12),
                            const Text('Fit page'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'first_page',
                        child: Row(
                          children: [
                            Icon(Icons.first_page_rounded, size: 20),
                            const SizedBox(width: 12),
                            const Text('First page'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'last_page',
                        child: Row(
                          children: [
                            Icon(Icons.last_page_rounded, size: 20),
                            const SizedBox(width: 12),
                            const Text('Last page'),
                          ],
                        ),
                      ),
                    ],
                ),
              ],
            )
          : AppBar(
              title: Text(
                widget.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: colors.error.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _buildPdfViewer(),
    );
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        PdfViewer.file(
          widget.filePath,
          key: ValueKey(_darkMode),
          controller: _controller,
          params: PdfViewerParams(
            scrollPhysics: const FixedOverscrollPhysics(maxOverscroll: 120),
            backgroundColor:
                _darkMode ? const Color(0xFF1E1E1E) : Colors.grey,
            onPageChanged: (pageNumber) {
              if (pageNumber != null && mounted) {
                setState(() => _currentPage = pageNumber);
              }
            },
            onDocumentLoadFinished: (documentRef, loadSucceeded) {
              if (loadSucceeded && mounted) {
                setState(() => _totalPages = _controller.pageCount);
              }
            },
            viewerOverlayBuilder: (context, size, handleLinkTap) => [
              PdfViewerScrollThumb(
                controller: _controller,
                orientation: ScrollbarOrientation.right,
              ),
              PdfViewerScrollThumb(
                controller: _controller,
                orientation: ScrollbarOrientation.bottom,
              ),
            ],
          ),
        ),
        if (_totalPages > 0)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _darkMode
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page $_currentPage of $_totalPages',
                  style: TextStyle(
                    color: _darkMode ? Colors.white : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'zoom_in':
      case 'zoom_out':
      case 'fit_page':
        _controller.goToPage(
          pageNumber: _controller.pageNumber ?? 1,
          anchor: PdfPageAnchor.top,
          duration: const Duration(milliseconds: 200),
        );
        break;
      case 'first_page':
        _controller.goToPage(
          pageNumber: 1,
          duration: const Duration(milliseconds: 200),
        );
        break;
      case 'last_page':
        _controller.goToPage(
          pageNumber: _totalPages,
          anchor: PdfPageAnchor.top,
          duration: const Duration(milliseconds: 200),
        );
        break;
    }
  }

  void _showPageJumpDialog() {
    final textController =
        TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to page'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter page number (1-$_totalPages)',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            _jumpToPage(value);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _jumpToPage(textController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _jumpToPage(String value) {
    final page = int.tryParse(value);
    if (page != null && page >= 1 && page <= _totalPages) {
      _controller.goToPage(
        pageNumber: page,
        duration: const Duration(milliseconds: 200),
      );
    }
  }
}

class _UnsupportedViewer extends StatelessWidget {
  final String filePath;
  final String fileName;
  final String fileType;

  const _UnsupportedViewer({
    required this.filePath,
    required this.fileName,
    required this.fileType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          fileName,
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
                  color: fileColor(fileType).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  fileIcon(fileType),
                  size: 40,
                  color: fileColor(fileType),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                fileName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'File saved to: $filePath',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This file type is not supported for viewing.',
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
}
