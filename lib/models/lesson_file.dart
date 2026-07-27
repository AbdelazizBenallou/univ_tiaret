class LessonFile {
  final int id;
  final String name;
  final String description;
  final String url;
  final String fileType;
  final int moduleId;
  final int activityTypeId;
  final String activityType;
  final int seasonId;
  final String uploadedAt;

  LessonFile({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.fileType,
    required this.moduleId,
    required this.activityTypeId,
    required this.activityType,
    required this.seasonId,
    required this.uploadedAt,
  });

  factory LessonFile.fromJson(Map<String, dynamic> json) {
    return LessonFile(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      fileType: json['file_type'] as String? ?? '',
      moduleId: json['module_id'] as int? ?? 0,
      activityTypeId: json['activity_type_id'] as int? ?? 0,
      activityType: json['activity_type'] as String? ?? '',
      seasonId: json['season_id'] as int? ?? 0,
      uploadedAt: json['uploaded_at'] as String? ?? '',
    );
  }

  String get fileIcon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'pdf';
      case 'docx':
      case 'doc':
        return 'doc';
      case 'pptx':
      case 'ppt':
        return 'ppt';
      case 'mp4':
      case 'avi':
      case 'mkv':
        return 'video';
      case 'mp3':
      case 'wav':
        return 'audio';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      default:
        return 'file';
    }
  }
}
