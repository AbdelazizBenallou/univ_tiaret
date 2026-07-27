import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

class _TextRun {
  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final double fontSize;
  final Color? color;
  final bool superscript;
  final bool subscript;

  const _TextRun({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.fontSize = 14,
    this.color,
    this.superscript = false,
    this.subscript = false,
  });
}

class _DocParagraph {
  final List<_TextRun> runs;
  final int headingLevel;
  final bool isBullet;
  final int bulletLevel;
  final bool isNumbered;
  final int numberingId;
  final int numberingLevel;
  final TextAlign alignment;
  final bool isPageBreak;

  const _DocParagraph({
    required this.runs,
    this.headingLevel = 0,
    this.isBullet = false,
    this.bulletLevel = 0,
    this.isNumbered = false,
    this.numberingId = 0,
    this.numberingLevel = 0,
    this.alignment = TextAlign.left,
    this.isPageBreak = false,
  });
}

class _TableInfo {
  final List<List<List<_TextRun>>> cells;
  const _TableInfo(this.cells);
}

class _Slide {
  final List<_DocParagraph> paragraphs;
  final String slideNumber;
  const _Slide({required this.paragraphs, required this.slideNumber});
}

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
  final List<_DocParagraph> _paragraphs = [];
  final List<_TableInfo> _tables = [];
  final List<_Slide> _slides = [];
  List<List<String>> _spreadsheetData = [];
  String? _error;
  bool _loading = true;
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
      final archive = ZipDecoder().decodeBytes(bytes);
      final t = widget.fileType.toLowerCase();

      if (t == 'docx' || t == 'doc') {
        _parseDocx(archive);
      } else if (t == 'pptx' || t == 'ppt') {
        _parsePptx(archive);
      } else if (t == 'xlsx' || t == 'xls') {
        _parseXlsx(archive);
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to read file: $e';
        _loading = false;
      });
    }
  }

  void _parseDocx(Archive archive) {
    final docFile = archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => ArchiveFile('', 0, []),
    );
    final xml = utf8.decode(docFile.content as List<int>, allowMalformed: true);

    final bodyMatch = RegExp(r'<w:body>(.*?)</w:body>', dotAll: true).firstMatch(xml);
    if (bodyMatch == null) return;
    final body = bodyMatch.group(1)!;

    final pPattern = RegExp(r'<w:p[\s>].*?</w:p>', dotAll: true);
    for (final pMatch in pPattern.allMatches(body)) {
      final pXml = pMatch.group(0)!;
      final runs = _parseRuns(pXml);
      if (runs.isEmpty) continue;
      if (runs.every((r) => r.text.trim().isEmpty)) continue;

      int headingLevel = 0;
      bool isBullet = false;
      int bulletLevel = 0;
      bool isNumbered = false;
      int numberingId = 0;
      int numberingLevel = 0;
      TextAlign alignment = TextAlign.left;
      bool isPageBreak = false;

      if (RegExp(r'<w:br[^>]*w:type="page"').hasMatch(pXml) ||
          RegExp(r'<w:lastRenderedPageBreak').hasMatch(pXml)) {
        isPageBreak = true;
      }

      final pPrMatch = RegExp(r'<w:pPr>(.*?)</w:pPr>', dotAll: true).firstMatch(pXml);
      if (pPrMatch != null) {
        final pPr = pPrMatch.group(1)!;

        final olMatch = RegExp(r'w:outlineLvl\s+w:val="(\d+)"').firstMatch(pPr);
        if (olMatch != null) {
          headingLevel = int.parse(olMatch.group(1)!) + 1;
        }

        if (RegExp(r'<w:numPr>').hasMatch(pPr)) {
          final ilvlMatch = RegExp(r'w:ilvl\s+w:val="(\d+)"').firstMatch(pPr);
          final numIdMatch = RegExp(r'w:numId\s+w:val="(\d+)"').firstMatch(pPr);
          numberingLevel = ilvlMatch != null ? int.parse(ilvlMatch.group(1)!) : 0;
          numberingId = numIdMatch != null ? int.parse(numIdMatch.group(1)!) : 0;
          if (numberingId > 0) {
            isNumbered = true;
          }
        }

        final jcMatch = RegExp(r'w:jc\s+w:val="(\w+)"').firstMatch(pPr);
        if (jcMatch != null) {
          final jc = jcMatch.group(1)!;
          if (jc == 'center') {
            alignment = TextAlign.center;
          } else if (jc == 'right' || jc == 'end') {
            alignment = TextAlign.right;
          } else if (jc == 'both' || jc == 'distribute') {
            alignment = TextAlign.justify;
          }
        }

        final styleMatch = RegExp(r'w:styleId="([^"]*)"').firstMatch(pPr);
        if (styleMatch != null) {
          final styleId = styleMatch.group(1)!;
          if (styleId.toLowerCase().contains('heading')) {
            final num = RegExp(r'(\d+)').firstMatch(styleId);
            headingLevel = num != null ? int.parse(num.group(1)!) : 1;
          }
          if (styleId.toLowerCase().contains('list') ||
              styleId.toLowerCase().contains('bullet')) {
            isBullet = true;
            bulletLevel = numberingLevel;
          }
        }
      }

      _paragraphs.add(_DocParagraph(
        runs: runs,
        headingLevel: headingLevel,
        isBullet: isBullet,
        bulletLevel: bulletLevel,
        isNumbered: isNumbered,
        numberingId: numberingId,
        numberingLevel: numberingLevel,
        alignment: alignment,
        isPageBreak: isPageBreak,
      ));
    }

    final tblPattern = RegExp(r'<w:tbl>.*?</w:tbl>', dotAll: true);
    for (final tblMatch in tblPattern.allMatches(body)) {
      final tblXml = tblMatch.group(0)!;
      final rows = <List<List<_TextRun>>>[];
      final trPattern = RegExp(r'<w:tr[\s>].*?</w:tr>', dotAll: true);
      for (final trMatch in trPattern.allMatches(tblXml)) {
        final trXml = trMatch.group(0)!;
        final cells = <List<_TextRun>>[];
        final tcPattern = RegExp(r'<w:tc[\s>].*?</w:tc>', dotAll: true);
        for (final tcMatch in tcPattern.allMatches(trXml)) {
          final tcXml = tcMatch.group(0)!;
          final cellRuns = <_TextRun>[];
          final innerP = RegExp(r'<w:p[\s>].*?</w:p>', dotAll: true);
          for (final ipMatch in innerP.allMatches(tcXml)) {
            cellRuns.addAll(_parseRuns(ipMatch.group(0)!));
          }
          cells.add(cellRuns);
        }
        if (cells.isNotEmpty) rows.add(cells);
      }
      if (rows.isNotEmpty) _tables.add(_TableInfo(rows));
    }
  }

  List<_TextRun> _parseRuns(String pXml) {
    final runs = <_TextRun>[];
    final rPattern = RegExp(r'<w:r[\s>].*?</w:r>', dotAll: true);
    for (final rMatch in rPattern.allMatches(pXml)) {
      final rXml = rMatch.group(0)!;
      bool bold = false;
      bool italic = false;
      bool underline = false;
      bool strikethrough = false;
      double fontSize = 14;
      Color? color;
      bool superscript = false;
      bool subscript = false;

      final rPrMatch = RegExp(r'<w:rPr>(.*?)</w:rPr>', dotAll: true).firstMatch(rXml);
      if (rPrMatch != null) {
        final rPr = rPrMatch.group(1)!;
        if (RegExp(r'<w:b\s*/>').hasMatch(rPr) ||
            RegExp(r'<w:b\s+w:val="true"').hasMatch(rPr) ||
            RegExp(r'<w:b\s+w:val="1"').hasMatch(rPr)) {
          bold = true;
        }
        if (RegExp(r'<w:i\s*/>').hasMatch(rPr) ||
            RegExp(r'<w:i\s+w:val="true"').hasMatch(rPr) ||
            RegExp(r'<w:i\s+w:val="1"').hasMatch(rPr)) {
          italic = true;
        }
        if (RegExp(r'<w:u\s+w:val="(single|double|thick|wave|dash|dot)"').hasMatch(rPr)) {
          underline = true;
        }
        if (RegExp(r'<w:strike\s*/>').hasMatch(rPr) ||
            RegExp(r'<w:strike\s+w:val="true"').hasMatch(rPr)) {
          strikethrough = true;
        }
        if (RegExp(r'<w:vertAlign\s+w:val="superscript"').hasMatch(rPr)) {
          superscript = true;
        }
        if (RegExp(r'<w:vertAlign\s+w:val="subscript"').hasMatch(rPr)) {
          subscript = true;
        }

        final szMatch = RegExp(r'w:val="(\d+)"').firstMatch(
            rPr.replaceAll(RegExp(r'<[^>]*>'), ' '));
        if (szMatch != null) {
          final val = int.tryParse(szMatch.group(1)!);
          if (val != null && val > 0 && val < 200) {
            fontSize = val / 2.0;
          }
        }

        final colorMatch = RegExp(r'w:color\s+w:val="([0-9A-Fa-f]{6})"').firstMatch(rPr);
        if (colorMatch != null) {
          try {
            color = Color(int.parse('FF${colorMatch.group(1)!}', radix: 16));
          } catch (_) {}
        }
      }

      final tMatches = RegExp(r'<w:t[^>]*>([^<]*)</w:t>', dotAll: true).allMatches(rXml);
      final text = tMatches.map((m) => m.group(1) ?? '').join();
      if (text.isNotEmpty) {
        runs.add(_TextRun(
          text: text,
          bold: bold,
          italic: italic,
          underline: underline,
          strikethrough: strikethrough,
          fontSize: fontSize,
          color: color,
          superscript: superscript,
          subscript: subscript,
        ));
      }
    }

    final brMatches = RegExp(r'<w:br[^/]*/>').allMatches(pXml);
    for (final _ in brMatches) {
      runs.add(const _TextRun(text: '\n'));
    }
    return runs;
  }

  void _parsePptx(Archive archive) {
    final slideFiles = archive.files
        .where((f) => RegExp(r'ppt/slides/slide\d+\.xml$').hasMatch(f.name))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (int i = 0; i < slideFiles.length; i++) {
      final slideFile = slideFiles[i];
      final xml =
          utf8.decode(slideFile.content as List<int>, allowMalformed: true);
      final paragraphs = _parsePptxParagraphs(xml);
      _slides.add(_Slide(paragraphs: paragraphs, slideNumber: '${i + 1}'));
    }
  }

  List<_DocParagraph> _parsePptxParagraphs(String xml) {
    final paragraphs = <_DocParagraph>[];
    final pPattern = RegExp(r'<a:p[\s>].*?</a:p>', dotAll: true);
    for (final pMatch in pPattern.allMatches(xml)) {
      final pXml = pMatch.group(0)!;
      final runs = <_TextRun>[];

      final rPattern = RegExp(r'<a:r[\s>].*?</a:r>', dotAll: true);
      for (final rMatch in rPattern.allMatches(pXml)) {
        final rXml = rMatch.group(0)!;
        bool bold = false;
        bool italic = false;
        bool underline = false;
        double fontSize = 18;
        Color? color;

        final rPrMatch = RegExp(r'<a:rPr[^/]*/>', dotAll: true).firstMatch(rXml);
        if (rPrMatch != null) {
          final rPr = rPrMatch.group(0)!;
          if (RegExp(r'b="1"').hasMatch(rPr)) bold = true;
          if (RegExp(r'i="1"').hasMatch(rPr)) italic = true;
          if (RegExp(r'u="sng"').hasMatch(rPr) || RegExp(r'udl="1"').hasMatch(rPr)) {
            underline = true;
          }
          final szMatch = RegExp(r'sz="(\d+)"').firstMatch(rPr);
          if (szMatch != null) {
            final val = int.tryParse(szMatch.group(1)!);
            if (val != null && val > 0) fontSize = val / 100.0;
          }
          final solidMatch = RegExp(r'<a:solidFill>(.*?)</a:solidFill>', dotAll: true)
              .firstMatch(rPr);
          if (solidMatch != null) {
            final colorMatch = RegExp(r'val="([0-9A-Fa-f]{6})"')
                .firstMatch(solidMatch.group(1)!);
            if (colorMatch != null) {
              try {
                color = Color(int.parse('FF${colorMatch.group(1)!}', radix: 16));
              } catch (_) {}
            }
          }
        }

        final tMatch = RegExp(r'<a:t>([^<]*)</a:t>').allMatches(rXml);
        final text = tMatch.map((m) => m.group(1) ?? '').join();
        if (text.isNotEmpty) {
          runs.add(_TextRun(
            text: text,
            bold: bold,
            italic: italic,
            underline: underline,
            fontSize: fontSize,
            color: color,
          ));
        }
      }
      if (runs.isNotEmpty) {
        TextAlign alignment = TextAlign.left;
        if (RegExp(r'alg="ctr"').hasMatch(pXml) || RegExp(r'align="ctr"').hasMatch(pXml)) {
          alignment = TextAlign.center;
        } else if (RegExp(r'alg="r"').hasMatch(pXml) || RegExp(r'align="r"').hasMatch(pXml)) {
          alignment = TextAlign.right;
        }
        paragraphs.add(_DocParagraph(runs: runs, alignment: alignment));
      }
    }
    return paragraphs;
  }

  void _parseXlsx(Archive archive) {
    final sharedStrings = <String>[];

    final ssFile = archive.files.firstWhere(
      (f) => f.name == 'xl/sharedStrings.xml',
      orElse: () => ArchiveFile('', 0, []),
    );
    final ssXml =
        utf8.decode(ssFile.content as List<int>, allowMalformed: true);
    final siPattern = RegExp(r'<si>(.*?)</si>', dotAll: true);
    final tPattern = RegExp(r'<t[^>]*>([^<]*)</t>', dotAll: true);
    for (final siMatch in siPattern.allMatches(ssXml)) {
      final texts = tPattern.allMatches(siMatch.group(0)!);
      sharedStrings.add(texts.map((m) => m.group(1) ?? '').join());
    }

    final sheetFiles = archive.files
        .where((f) => RegExp(r'xl/worksheets/sheet\d+\.xml$').hasMatch(f.name))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final sheetFile in sheetFiles) {
      final xml =
          utf8.decode(sheetFile.content as List<int>, allowMalformed: true);
      final rows = <List<String>>[];
      final rowPattern = RegExp(r'<row[^>]*>(.*?)</row>', dotAll: true);
      final cellPattern = RegExp(r'<c[^>]*r="[A-Z]+\d+"[^>]*>(.*?)</c>', dotAll: true);
      final vPattern = RegExp(r'<v>([^<]*)</v>');

      for (final rowMatch in rowPattern.allMatches(xml)) {
        final rowXml = rowMatch.group(1)!;
        final cells = <String>[];
        for (final cellMatch in cellPattern.allMatches(rowXml)) {
          final cellXml = cellMatch.group(1)!;
          final typeMatch = RegExp(r't="s"').hasMatch(cellMatch.group(0)!);
          final vMatch = vPattern.firstMatch(cellXml);
          final value = vMatch?.group(1) ?? '';
          if (typeMatch && value.isNotEmpty) {
            final idx = int.tryParse(value);
            if (idx != null && idx < sharedStrings.length) {
              cells.add(sharedStrings[idx]);
            } else {
              cells.add(value);
            }
          } else {
            cells.add(value);
          }
        }
        if (cells.isNotEmpty) rows.add(cells);
      }
      if (rows.isNotEmpty) {
        _spreadsheetData = rows;
        break;
      }
    }
  }

  void _toggleAppBar() {
    setState(() => _showAppBar = !_showAppBar);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _showAppBar
          ? AppBar(
              title: Text(
                widget.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
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
                        Icon(Icons.error_outline_rounded, size: 48,
                            color: colors.error.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(_error!, maxLines: 8, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14,
                              color: colors.onSurface.withValues(alpha: 0.6)),
                          textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _toggleAppBar,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    final t = widget.fileType.toLowerCase();
    if (t == 'docx' || t == 'doc') return _buildDocxView();
    if (t == 'pptx' || t == 'ppt') return _buildPptxView();
    if (t == 'xlsx' || t == 'xls') return _buildXlsxView();
    return const Center(child: Text('Unsupported format'));
  }

  Widget _buildDocxView() {
    if (_paragraphs.isEmpty && _tables.isEmpty) {
      return const Center(child: Text('No content found'));
    }

    final items = <Widget>[];

    for (final p in _paragraphs) {
      if (p.isPageBreak) {
        items.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          height: 1,
          color: Colors.grey.withValues(alpha: 0.3),
        ));
        continue;
      }
      items.add(_buildDocParagraph(p));
    }

    for (final table in _tables) {
      items.add(_buildTable(table));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        ),
      ),
    );
  }

  Widget _buildDocParagraph(_DocParagraph p) {
    final baseSize = 14.0;
    double fontSize = baseSize;

    if (p.headingLevel > 0) {
      if (p.headingLevel == 1) { fontSize = 24; }
      else if (p.headingLevel == 2) { fontSize = 20; }
      else if (p.headingLevel == 3) { fontSize = 17; }
      else { fontSize = 15; }
    }

    final textSpans = p.runs.map((run) {
      double sz = run.fontSize;
      if (p.headingLevel > 0) {
        sz = fontSize;
      }

      return TextSpan(
        text: run.text,
        style: TextStyle(
          fontSize: sz,
          fontWeight: run.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: run.italic ? FontStyle.italic : FontStyle.normal,
          decoration: TextDecoration.combine([
            if (run.underline) TextDecoration.underline,
            if (run.strikethrough) TextDecoration.lineThrough,
          ]),
          color: run.color ?? Colors.black87,
          height: 1.5,
          fontFeatures: [
            if (run.superscript) const FontFeature.superscripts(),
            if (run.subscript) const FontFeature.subscripts(),
          ],
        ),
      );
    }).toList();

    double topMargin = 4;
    double bottomMargin = 4;
    if (p.headingLevel > 0) {
      topMargin = p.headingLevel <= 2 ? 20 : 14;
      bottomMargin = p.headingLevel <= 2 ? 10 : 6;
    }

    Widget child;
    if (p.isBullet || p.isNumbered) {
      final indent = 20.0 + (p.bulletLevel * 20);
      child = Padding(
        padding: EdgeInsets.only(left: indent),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: Text('•', style: TextStyle(
                  fontSize: p.headingLevel > 0 ? fontSize : baseSize,
                  color: Colors.black87)),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(children: textSpans),
              ),
            ),
          ],
        ),
      );
    } else {
      child = RichText(
        textAlign: p.alignment,
        text: TextSpan(children: textSpans),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: topMargin, bottom: bottomMargin),
      child: child,
    );
  }

  Widget _buildTable(_TableInfo table) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: table.cells.asMap().entries.map((entry) {
          final rowIdx = entry.key;
          final row = entry.value;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: row.asMap().entries.map((cellEntry) {
                final cellRuns = cellEntry.value;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: rowIdx == 0 ? const Color(0xFFF5F5F5) : Colors.white,
                      border: Border(
                        right: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3)),
                        bottom: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: cellRuns.map((run) => TextSpan(
                          text: run.text,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: run.bold ? FontWeight.bold : FontWeight.normal,
                            fontStyle: run.italic ? FontStyle.italic : FontStyle.normal,
                            color: run.color ?? Colors.black87,
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPptxView() {
    if (_slides.isEmpty) {
      return const Center(child: Text('No slides found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _slides.length,
      itemBuilder: (ctx, i) {
        final slide = _slides[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: slide.paragraphs.map((p) {
                    final textSpans = p.runs.map((run) => TextSpan(
                      text: run.text,
                      style: TextStyle(
                        fontSize: run.fontSize,
                        fontWeight: run.bold ? FontWeight.bold : FontWeight.normal,
                        fontStyle: run.italic ? FontStyle.italic : FontStyle.normal,
                        decoration: TextDecoration.combine([
                          if (run.underline) TextDecoration.underline,
                        ]),
                        color: run.color ?? Colors.black87,
                        height: 1.4,
                      ),
                    )).toList();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RichText(
                        textAlign: p.alignment,
                        text: TextSpan(children: textSpans),
                      ),
                    );
                  }                  ).toList(),
                ),
              ),
            ),
            ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Slide ${slide.slideNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildXlsxView() {
    if (_spreadsheetData.isEmpty) {
      return const Center(child: Text('No data found'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int row = 0; row < _spreadsheetData.length; row++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int col = 0; col < _spreadsheetData[row].length; col++)
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: row == 0 ? const Color(0xFFE8F5E9) : Colors.white,
                          border: Border(
                            right: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                            bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                        ),
                        child: Text(
                          _spreadsheetData[row][col],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: row == 0 ? FontWeight.w600 : FontWeight.normal,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
