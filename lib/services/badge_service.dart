import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BadgeService {
  static final ValueNotifier<int> notificationCount = ValueNotifier<int>(0);
}

class BadgeCountNotifier extends StateNotifier<int> {
  BadgeCountNotifier() : super(BadgeService.notificationCount.value) {
    BadgeService.notificationCount.addListener(_onChange);
  }

  void _onChange() {
    state = BadgeService.notificationCount.value;
  }

  @override
  void dispose() {
    BadgeService.notificationCount.removeListener(_onChange);
    super.dispose();
  }
}

final badgeNotificationCountProvider =
    StateNotifierProvider<BadgeCountNotifier, int>((ref) => BadgeCountNotifier());
