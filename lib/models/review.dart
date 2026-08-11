class ReviewUser {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? avatar;

  ReviewUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.avatar,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return ReviewUser(
      id: json['id'] as int,
      firstName: profiles?['first_name'] as String?,
      lastName: profiles?['last_name'] as String?,
      avatar: profiles?['avatar'] as String?,
    );
  }
}

class Review {
  final int id;
  final String comment;
  final ReviewUser? user;
  final String createdAt;
  final String updatedAt;

  Review({
    required this.id,
    required this.comment,
    this.user,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      comment: json['comment'] as String? ?? '',
      user: json['users'] != null
          ? ReviewUser.fromJson(json['users'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  String get authorName {
    if (user == null) return '';
    final first = user!.firstName ?? '';
    final last = user!.lastName ?? '';
    return '$first $last'.trim();
  }
}
