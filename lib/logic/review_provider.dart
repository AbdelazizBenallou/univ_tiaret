import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/models/review.dart';
import 'package:univ_tiaret/services/review_service.dart';

class MyReviewState {
  final Review? review;
  final bool loading;
  final String? error;

  MyReviewState({this.review, this.loading = false, this.error});

  MyReviewState copyWith({Review? review, bool? loading, String? error}) {
    return MyReviewState(
      review: review ?? this.review,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class MyReviewNotifier extends StateNotifier<MyReviewState> {
  MyReviewNotifier() : super(MyReviewState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final review = await ReviewService.getMyReview();
      state = MyReviewState(review: review, loading: false);
    } catch (e) {
      state = MyReviewState(loading: false, error: e.toString());
    }
  }

  Future<bool> submit(String comment) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final review = await ReviewService.submitReview(comment);
      state = MyReviewState(review: review, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
}

final myReviewProvider = StateNotifierProvider<MyReviewNotifier, MyReviewState>(
  (ref) {
    return MyReviewNotifier();
  },
);

class MyReviewsListState {
  final List<Review> reviews;
  final bool loading;
  final String? error;

  MyReviewsListState({
    this.reviews = const [],
    this.loading = false,
    this.error,
  });
}

class MyReviewsListNotifier extends StateNotifier<MyReviewsListState> {
  MyReviewsListNotifier() : super(MyReviewsListState()) {
    load();
  }

  int _page = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  Future<void> load() async {
    state = MyReviewsListState(loading: true);
    _page = 1;
    try {
      final result = await ReviewService.getMyReviews(page: 1);
      state = MyReviewsListState(reviews: result.reviews);
      _hasMore = _page < result.totalPages;
    } catch (e) {
      state = MyReviewsListState(error: e.toString());
      _hasMore = false;
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !_hasMore) return;
    state = MyReviewsListState(reviews: state.reviews, loading: true);
    _page++;
    try {
      final result = await ReviewService.getMyReviews(page: _page);
      state = MyReviewsListState(
        reviews: [...state.reviews, ...result.reviews],
      );
      _hasMore = _page < result.totalPages;
    } catch (e) {
      _page--;
      state = MyReviewsListState(reviews: state.reviews, error: e.toString());
    }
  }
}

final myReviewsListProvider =
    StateNotifierProvider<MyReviewsListNotifier, MyReviewsListState>((ref) {
      return MyReviewsListNotifier();
    });

class AllReviewsListNotifier extends StateNotifier<MyReviewsListState> {
  AllReviewsListNotifier() : super(MyReviewsListState());

  int _page = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  Future<void> load() async {
    state = MyReviewsListState(loading: true);
    _page = 1;
    try {
      final result = await ReviewService.getAllReviews(page: 1);
      state = MyReviewsListState(reviews: result.reviews);
      _hasMore = _page < result.totalPages;
    } catch (e) {
      state = MyReviewsListState(error: e.toString());
      _hasMore = false;
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !_hasMore) return;
    state = MyReviewsListState(reviews: state.reviews, loading: true);
    _page++;
    try {
      final result = await ReviewService.getAllReviews(page: _page);
      state = MyReviewsListState(
        reviews: [...state.reviews, ...result.reviews],
      );
      _hasMore = _page < result.totalPages;
    } catch (e) {
      _page--;
      state = MyReviewsListState(reviews: state.reviews, error: e.toString());
    }
  }
}

final allReviewsListProvider =
    StateNotifierProvider<AllReviewsListNotifier, MyReviewsListState>((ref) {
      return AllReviewsListNotifier();
    });
