import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:univ_tiaret/constants.dart';

enum FileCategory { pdf, image, text, code, office, video, audio, unknown }

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
  if (const {
    'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v', '3gp', 'mpg',
    'mpeg', 'm2ts', 'ogv',
  }.contains(t)) {
    return FileCategory.video;
  }
  if (const {
    'mp3', 'wav', 'flac', 'aac', 'ogg', 'opus', 'm4a', 'wma', 'mid', 'midi',
    'amr', 'aiff', 'ape',
  }.contains(t)) {
    return FileCategory.audio;
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
    case 'wmv':
    case 'flv':
    case 'webm':
    case 'm4v':
    case '3gp':
    case 'mpg':
    case 'mpeg':
    case 'm2ts':
    case 'ogv':
      return AppColors.primaryColor;
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'aac':
    case 'ogg':
    case 'opus':
    case 'm4a':
    case 'wma':
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
      return LucideIcons.fileText;
    case 'docx':
    case 'doc':
      return LucideIcons.fileText;
    case 'pptx':
    case 'ppt':
      return LucideIcons.presentation;
    case 'xlsx':
    case 'xls':
      return LucideIcons.fileSpreadsheet;
    case 'odt':
    case 'ods':
    case 'odp':
      return LucideIcons.fileText;
    case 'mp4':
    case 'avi':
    case 'mkv':
    case 'mov':
    case 'wmv':
    case 'flv':
    case 'webm':
    case 'm4v':
    case '3gp':
    case 'mpg':
    case 'mpeg':
    case 'm2ts':
    case 'ogv':
      return LucideIcons.fileVideo;
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'aac':
    case 'ogg':
    case 'opus':
    case 'm4a':
    case 'wma':
      return LucideIcons.fileAudio;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'webp':
      return LucideIcons.image;
    case 'svg':
      return LucideIcons.palette;
    case 'txt':
    case 'md':
    case 'log':
      return LucideIcons.fileText;
    case 'csv':
      return LucideIcons.fileSpreadsheet;
    case 'py':
    case 'java':
    case 'dart':
    case 'js':
    case 'jsx':
    case 'ts':
    case 'tsx':
    case 'c':
    case 'cpp':
    case 'h':
    case 'cs':
    case 'go':
    case 'rs':
    case 'kt':
    case 'php':
      return LucideIcons.fileCode;
    case 'sql':
      return LucideIcons.database;
    case 'html':
    case 'css':
      return LucideIcons.fileCode;
    case 'sh':
    case 'bat':
      return LucideIcons.terminal;
    case 'json':
      return LucideIcons.fileCode;
    case 'xml':
    case 'yaml':
    case 'yml':
      return LucideIcons.fileCode;
    default:
      return LucideIcons.file;
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
