import 'package:flutter/material.dart';

import 'package:univ_tiaret/constants.dart';

enum FileCategory { pdf, image, text, code, office, unknown }

FileCategory fileCategory(String type) {
  final t = type.toLowerCase().trim();
  if (t == 'pdf') {
    return FileCategory.pdf;
  }
  if (const {
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg',
  }.contains(t)) {
    return FileCategory.image;
  }
  if (const {
    'txt', 'md', 'log', 'csv', 'ini', 'cfg', 'conf', 'toml',
  }.contains(t)) {
    return FileCategory.text;
  }
  if (const {
    'py', 'java', 'dart', 'js', 'ts', 'jsx', 'tsx', 'c', 'cpp', 'h',
    'cs', 'rb', 'go', 'rs', 'kt', 'swift', 'php', 'sql', 'html', 'css',
    'scss', 'less', 'sh', 'bat', 'ps1', 'yaml', 'yml', 'json', 'xml',
  }.contains(t)) {
    return FileCategory.code;
  }
  if (const {
    'docx', 'doc', 'pptx', 'ppt', 'xlsx', 'xls', 'odt', 'ods', 'odp',
  }.contains(t)) {
    return FileCategory.office;
  }
  return FileCategory.unknown;
}

FileCategory fileCategoryFromPath(String filePath) {
  final ext = filePath.split('.').last.toLowerCase().trim();
  final byExt = fileCategory(ext);
  if (byExt != FileCategory.unknown) return byExt;
  final nameLower = filePath.split('/').last.toLowerCase();
  if (nameLower.endsWith('.pdf')) return FileCategory.pdf;
  if (RegExp(r'\.(jpg|jpeg|png|gif|bmp|webp|svg)$').hasMatch(nameLower)) {
    return FileCategory.image;
  }
  return FileCategory.unknown;
}

Color fileColor(String type) {
  switch (type.toLowerCase()) {
    case 'pdf':
      return const Color(0xFFEA5B5B);
    case 'docx':
    case 'doc':
      return const Color(0xFF2A93D5);
    case 'pptx':
    case 'ppt':
      return const Color(0xFFFF8C42);
    case 'xlsx':
    case 'xls':
      return const Color(0xFF27AE60);
    case 'odt':
    case 'ods':
    case 'odp':
      return const Color(0xFF2196F3);
    case 'mp4':
    case 'avi':
    case 'mkv':
    case 'mov':
      return const Color(0xFF9B59B6);
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'aac':
      return const Color(0xFF2ED573);
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'webp':
      return const Color(0xFFFFBE21);
    case 'svg':
      return const Color(0xFFFF6B81);
    case 'txt':
    case 'md':
    case 'log':
      return const Color(0xFF95A5A6);
    case 'csv':
      return const Color(0xFF1ABC9C);
    case 'py':
      return const Color(0xFF306998);
    case 'java':
      return const Color(0xFFED8B00);
    case 'dart':
      return const Color(0xFF0175C2);
    case 'js':
    case 'jsx':
      return const Color(0xFFF7DF1E);
    case 'ts':
    case 'tsx':
      return const Color(0xFF3178C6);
    case 'c':
    case 'cpp':
    case 'h':
      return const Color(0xFF00599C);
    case 'cs':
      return const Color(0xFF239120);
    case 'go':
      return const Color(0xFF00ADD8);
    case 'rs':
      return const Color(0xFFDEA584);
    case 'kt':
      return const Color(0xFF7F52FF);
    case 'php':
      return const Color(0xFF777BB4);
    case 'html':
      return const Color(0xFFE34C26);
    case 'css':
      return const Color(0xFF264DE4);
    case 'sql':
      return const Color(0xFF4479A1);
    case 'sh':
    case 'bat':
      return const Color(0xFF4EAA25);
    case 'json':
      return const Color(0xFF292929);
    case 'xml':
    case 'yaml':
    case 'yml':
      return const Color(0xFFCB171E);
    default:
      return AppColors.greenAccent;
  }
}

IconData fileIcon(String type) {
  switch (type.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf_rounded;
    case 'docx':
    case 'doc':
      return Icons.description_rounded;
    case 'pptx':
    case 'ppt':
      return Icons.slideshow_rounded;
    case 'xlsx':
    case 'xls':
      return Icons.table_chart_rounded;
    case 'odt':
    case 'ods':
    case 'odp':
      return Icons.description_rounded;
    case 'mp4':
    case 'avi':
    case 'mkv':
    case 'mov':
      return Icons.videocam_rounded;
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'aac':
      return Icons.audiotrack_rounded;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'webp':
      return Icons.image_rounded;
    case 'svg':
      return Icons.palette_rounded;
    case 'txt':
    case 'md':
    case 'log':
      return Icons.description_rounded;
    case 'csv':
      return Icons.table_chart_rounded;
    case 'py':
      return Icons.code_rounded;
    case 'java':
      return Icons.code_rounded;
    case 'dart':
      return Icons.code_rounded;
    case 'js':
    case 'jsx':
      return Icons.code_rounded;
    case 'ts':
    case 'tsx':
      return Icons.code_rounded;
    case 'c':
    case 'cpp':
    case 'h':
      return Icons.code_rounded;
    case 'cs':
      return Icons.code_rounded;
    case 'go':
      return Icons.code_rounded;
    case 'rs':
      return Icons.code_rounded;
    case 'kt':
      return Icons.code_rounded;
    case 'php':
      return Icons.code_rounded;
    case 'sql':
      return Icons.storage_rounded;
    case 'html':
    case 'css':
      return Icons.code_rounded;
    case 'sh':
    case 'bat':
      return Icons.terminal_rounded;
    case 'json':
      return Icons.code_rounded;
    case 'xml':
    case 'yaml':
    case 'yml':
      return Icons.code_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String extensionLabel(String type) {
  return type.toUpperCase();
}
