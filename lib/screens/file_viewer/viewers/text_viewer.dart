import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class TextViewer extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String fileType;
  final bool isCode;

  const TextViewer({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    this.isCode = false,
  });

  @override
  State<TextViewer> createState() => _TextViewerState();
}

class _TextViewerState extends State<TextViewer> {
  String? _content;
  String? _error;
  bool _loading = true;
  bool _wordWrap = true;
  bool _showLineNumbers = true;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  void _loadFile() {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) {
        setState(() {
          _error = 'File not found';
          _loading = false;
        });
        return;
      }

      final bytes = file.readAsBytesSync();
      String text;
      if (bytes.length > 100 * 1024 * 1024) {
        text = 'File too large to display (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB)';
        setState(() {
          _content = text;
          _loading = false;
        });
        return;
      }

      try {
        text = utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        try {
          text = String.fromCharCodes(bytes);
        } catch (e) {
          setState(() {
            _error = 'Cannot read file: encoding not supported';
            _loading = false;
          });
          return;
        }
      }

      setState(() {
        _content = text;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to read file: $e';
        _loading = false;
      });
    }
  }

  void _toggleAppBar() {
    setState(() => _showAppBar = !_showAppBar);
  }

  List<String> get _lines => _content?.split('\n') ?? [];
  int get _lineCount => _lines.length;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: widget.isCode
          ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5))
          : null,
      appBar: _showAppBar
          ? AppBar(
              title: Text(
                widget.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                if (_content != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        '$_lineCount lines',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                if (widget.isCode)
                  IconButton(
                    onPressed: () =>
                        setState(() => _showLineNumbers = !_showLineNumbers),
                    icon: Icon(
                      _showLineNumbers
                          ? Icons.format_list_numbered_rounded
                          : Icons.format_list_bulleted_rounded,
                      size: 22,
                    ),
                    tooltip: _showLineNumbers
                        ? 'Hide line numbers'
                        : 'Show line numbers',
                  ),
                IconButton(
                  onPressed: () =>
                      setState(() => _wordWrap = !_wordWrap),
                  icon: Icon(
                    _wordWrap
                        ? Icons.wrap_text_rounded
                        : Icons.short_text_rounded,
                    size: 22,
                  ),
                  tooltip: _wordWrap ? 'Disable word wrap' : 'Enable word wrap',
                ),
              ],
            )
          : null,
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
              : GestureDetector(
                  onTap: _toggleAppBar,
                  child: widget.isCode
                      ? _buildCodeView(isDark)
                      : _buildTextView(isDark),
                ),
    );
  }

  Widget _buildCodeView(bool isDark) {
    final bgColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
    final textColor =
        isDark ? const Color(0xFFD4D4D4) : const Color(0xFF383A42);
    final lineNumColor =
        isDark ? const Color(0xFF5A5A5A) : const Color(0xFFB0B0B0);
    final gutterColor =
        isDark ? const Color(0xFF252526) : const Color(0xFFF0F0F0);
    final borderColor =
        isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE0E0E0);

    return Container(
      color: bgColor,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _lineCount,
        itemBuilder: (ctx, index) {
          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                bottom: BorderSide(
                  color: borderColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_showLineNumbers)
                    Container(
                      width: 56,
                      padding: const EdgeInsets.only(right: 12),
                      alignment: Alignment.centerRight,
                      color: gutterColor,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.6,
                          color: lineNumColor,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      child: SelectableText(
                        _lines[index],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.6,
                          color: textColor,
                        ),
                        scrollPhysics:
                            const NeverScrollableScrollPhysics(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextView(bool isDark) {
    final textColor =
        isDark ? const Color(0xFFD4D4D4) : const Color(0xFF383A42);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: SelectableText(
          _content ?? '',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.6,
            color: textColor,
          ),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }
}
