class FavoriteFile {
  final int? id;
  final int fileId;
  final String fileName;
  final String fileType;
  final String fileUrl;
  final int moduleId;
  final String moduleName;
  final int seasonId;
  final String seasonName;
  final String semesterName;
  final int activityTypeId;
  final String activityName;
  final String createdAt;

  FavoriteFile({
    this.id,
    required this.fileId,
    required this.fileName,
    this.fileType = '',
    this.fileUrl = '',
    this.moduleId = 0,
    this.moduleName = '',
    this.seasonId = 0,
    this.seasonName = '',
    this.semesterName = '',
    this.activityTypeId = 0,
    this.activityName = '',
    this.createdAt = '',
  });

  factory FavoriteFile.fromDb(Map<String, dynamic> map) {
    return FavoriteFile(
      id: map['id'] as int?,
      fileId: map['file_id'] as int,
      fileName: map['file_name'] as String? ?? '',
      fileType: map['file_type'] as String? ?? '',
      fileUrl: map['file_url'] as String? ?? '',
      moduleId: map['module_id'] as int? ?? 0,
      moduleName: map['module_name'] as String? ?? '',
      seasonId: map['season_id'] as int? ?? 0,
      seasonName: map['season_name'] as String? ?? '',
      semesterName: map['semester_name'] as String? ?? '',
      activityTypeId: map['activity_type_id'] as int? ?? 0,
      activityName: map['activity_name'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'file_id': fileId,
      'file_name': fileName,
      'file_type': fileType,
      'file_url': fileUrl,
      'module_id': moduleId,
      'module_name': moduleName,
      'season_id': seasonId,
      'season_name': seasonName,
      'semester_name': semesterName,
      'activity_type_id': activityTypeId,
      'activity_name': activityName,
      'created_at': createdAt,
    };
  }
}
