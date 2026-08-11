import 'package:univ_tiaret/models/review.dart';
import 'package:univ_tiaret/services/api_service.dart';

class ReviewListResult {
  final List<Review> reviews;
  final int totalPages;

  const ReviewListResult({required this.reviews, required this.totalPages});
}

class ReviewService {
  static Future<Review> submitReview(String comment) async {
    final res = await ApiService.post(
      '/v1/reviews',
      body: {'comment': comment},
    );
    if (res['success'] == true && res['data'] != null) {
      return Review.fromJson(res['data'] as Map<String, dynamic>);
    }
    throw Exception(res['message'] ?? 'Failed to submit review');
  }

  static Future<Review?> getMyReview() async {
    final res = await ApiService.get('/v1/reviews/me');
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'];
      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = data['data'] as List;
        if (list.isEmpty) return null;
        return Review.fromJson(list.first as Map<String, dynamic>);
      }
      return Review.fromJson(data as Map<String, dynamic>);
    }
    final msg = res['message'] as String?;
    if (msg != null &&
        (msg.toLowerCase().contains('not found') || res['success'] == false)) {
      return null;
    }
    if (msg != null) throw Exception(msg);
    return null;
  }

  static Future<ReviewListResult> getMyReviews({
    int page = 1,
    int perPage = 10,
  }) async {
    final res = await ApiService.get(
      '/v1/reviews/me?page=$page&perPage=$perPage',
    );
    return _parseList(res);
  }

  static Future<ReviewListResult> getAllReviews({
    int page = 1,
    int perPage = 10,
  }) async {
    final res = await ApiService.get(
      '/v1/reviews?page=$page&perPage=$perPage',
    );
    return _parseList(res);
  }

  static ReviewListResult _parseList(Map<String, dynamic> res) {
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'];
      if (data is List) {
        return ReviewListResult(
          reviews: data
              .map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList(),
          totalPages: 1,
        );
      }
      if (data is Map<String, dynamic>) {
        final list = data['data'] as List<dynamic>? ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>?;
        final totalPages = pagination?['totalPages'] as int? ?? 1;
        return ReviewListResult(
          reviews: list
              .map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList(),
          totalPages: totalPages,
        );
      }
    }
    return const ReviewListResult(reviews: [], totalPages: 0);
  }
}
