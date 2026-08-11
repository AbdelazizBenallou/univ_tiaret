import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/repositories/subscription_repository.dart';
import 'package:univ_tiaret/models/current_subscription.dart';
import 'package:univ_tiaret/models/subscription_demand.dart';
import 'package:univ_tiaret/services/api_service.dart';
import 'package:univ_tiaret/services/auth_service.dart';

final subscriptionProvider =
    ChangeNotifierProvider<SubscriptionProvider>((ref) => SubscriptionProvider());

class SubscriptionProvider extends ChangeNotifier {
  CurrentSubscription? _current;
  List<SubscriptionDemand> _demands = [];
  bool _loading = false;
  bool _loadedOnce = false;
  bool _saving = false;
  bool _loadError = false;
  String? _error;

  CurrentSubscription? get current {
    final c = _current;
    if (c == null) return null;
    final end = c.endDate;
    if (end != null && end.isBefore(DateTime.now())) return null;
    return c;
  }
  List<SubscriptionDemand> get demands => _demands;
  bool get loading => _loading;
  bool get loadedOnce => _loadedOnce;
  bool get saving => _saving;
  bool get loadError => _loadError;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    _loadError = false;
    notifyListeners();

    await Future.wait([_fetchAll(), _fetchCurrent(), _fetchDemands()]);

    if (_loadError && _current == null) {
      _current = await _fromCache();
    }

    _loadedOnce = true;
    _loading = false;
    notifyListeners();
  }

  Future<void> _fetchAll() async {
    try {
      final response = await ApiService.get('/v1/subscriptions/');
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          final subs = data
              .map((e) => CurrentSubscription.fromJson(e as Map<String, dynamic>))
              .toList();
          final userId = await _userId();
          if (userId != null) {
            await SubscriptionRepository.replaceAll(userId: userId, subs: subs);
          }
        }
      } else {
        _markNetworkError(response['message']);
      }
    } catch (e) {
      _markNetworkError(e);
    }
  }

  Future<void> _fetchCurrent() async {
    try {
      final response = await ApiService.get('/v1/subscriptions/current');
      if (response['success'] == true) {
        if (response['data'] != null) {
          final sub = CurrentSubscription.fromJson(
            response['data'] as Map<String, dynamic>,
          );
          final end = sub.endDate;
          if (end != null && end.isBefore(DateTime.now())) {
            _current = null;
          } else {
            _current = sub;
            final userId = await _userId();
            if (userId != null) {
              await SubscriptionRepository.upsert(sub, userId: userId);
            }
          }
        } else {
          _current = null;
          await SubscriptionRepository.clear();
        }
      } else {
        _markNetworkError(response['message']);
        _current = null;
      }
    } catch (e) {
      _markNetworkError(e);
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
      } else {
        _markNetworkError(response['message']);
      }
    } catch (e) {
      // silent
    }
  }

  Future<int?> _userId() async {
    final user = await AuthService.getUser();
    return user?.id;
  }

  Future<CurrentSubscription?> _fromCache() async {
    final userId = await _userId();
    if (userId == null) return null;
    return SubscriptionRepository.getActive(userId: userId);
  }

  void _markNetworkError(Object? message) {
    final msg = message?.toString().toLowerCase() ?? '';
    if (msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('unreachable')) {
      _loadError = true;
    }
  }

  Future<String?> createDemand({
    required int semesterId,
    int? specialityId,
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
          'speciality_id': ?specialityId,
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
