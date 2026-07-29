import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/models/current_subscription.dart';
import 'package:univ_tiaret/models/subscription_demand.dart';
import 'package:univ_tiaret/services/api_service.dart';

final subscriptionProvider =
    ChangeNotifierProvider<SubscriptionProvider>((ref) => SubscriptionProvider());

class SubscriptionProvider extends ChangeNotifier {
  CurrentSubscription? _current;
  List<SubscriptionDemand> _demands = [];
  bool _loading = false;
  bool _loadedOnce = false;
  bool _saving = false;
  String? _error;

  CurrentSubscription? get current => _current;
  List<SubscriptionDemand> get demands => _demands;
  bool get loading => _loading;
  bool get loadedOnce => _loadedOnce;
  bool get saving => _saving;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();

    await Future.wait([_fetchCurrent(), _fetchDemands()]);

    _loadedOnce = true;
    _loading = false;
    notifyListeners();
  }

  Future<void> _fetchCurrent() async {
    try {
      final response = await ApiService.get('/v1/subscriptions/current');
      if (response['success'] == true && response['data'] != null) {
        _current = CurrentSubscription.fromJson(
          response['data'] as Map<String, dynamic>,
        );
      } else {
        _current = null;
      }
    } catch (e) {
      _current = null;
    }
  }

  Future<void> _fetchDemands() async {
    try {
      final response = await ApiService.get('/v1/subscriptions/demands');
      if (response['success'] == true && response['data'] is List) {
        _demands = (response['data'] as List)
            .map((e) => SubscriptionDemand.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // silent
    }
  }

  Future<String?> createDemand({
    required int semesterId,
    required int specialityId,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/v1/subscriptions/demands',
        body: {
          'semester_id': semesterId,
          'type': 'premium',
          'speciality_id': specialityId,
        },
      );

      if (response['success'] == true) {
        await loadAll();
        _saving = false;
        notifyListeners();
        return null;
      }

      final msg = response['message'] as String? ?? 'Unknown error';
      _error = msg;
      _saving = false;
      notifyListeners();
      return msg;
    } catch (e) {
      _error = 'Network error';
      _saving = false;
      notifyListeners();
      return 'Network error';
    }
  }
}
