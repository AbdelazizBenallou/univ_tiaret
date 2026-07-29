import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/db.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/services/api_service.dart';

final profileProvider = ChangeNotifierProvider<ProfileProvider>((ref) {
  return ProfileProvider(ref);
});

class ProfileProvider extends ChangeNotifier {
  final Ref _ref;
  Map<String, dynamic>? _profile;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  ProfileProvider(this._ref);

  Map<String, dynamic>? get profile => _profile;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  Future<void> load() async {
    _error = null;
    _loading = true;
    notifyListeners();

    final cached = await ProfileRepository.get();
    if (cached != null) {
      _profile = cached;
      notifyListeners();
    }

    try {
      final response = await ApiService.get('/v1/users/me/profile');
      if (response['success'] == true && response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        _profile = _normalize(data);
        await ProfileRepository.upsert(_profile!);
      } else {
        _error = response['message'] as String? ?? 'Failed to load profile';
        if (_profile == null) await syncFromAuth();
      }
    } catch (e) {
      _error = 'Network error';
      if (_profile == null) await syncFromAuth();
    }

    _loading = false;
    notifyListeners();
  }

  Future<String?> update(Map<String, dynamic> fields) async {
    _saving = true;
    notifyListeners();

    try {
      final response = await ApiService.patch(
        '/v1/users/me/profile',
        body: fields,
      );

      if (response['success'] == true) {
        if (_profile != null) {
          _profile!.addAll(fields);
          await ProfileRepository.upsert(_profile!);
        }
        _saving = false;
        notifyListeners();
        return null;
      }

      _saving = false;
      notifyListeners();
      return response['message'] as String? ?? 'Update failed';
    } catch (e) {
      _saving = false;
      notifyListeners();
      return 'Network error';
    }
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> data) {
    final levels = data['levels'] as Map<String, dynamic>?;
    final specialities = data['specialities'] as Map<String, dynamic>?;
    final phoneProviders = data['phone_providers'] as Map<String, dynamic>?;

    return {
      'id': data['id'],
      'user_id': data['user_id'],
      'first_name': data['first_name'],
      'last_name': data['last_name'],
      'phone': data['phone'],
      'phone_provider_id': data['phone_provider_id'],
      'date_of_birth': data['date_of_birth'],
      'gender': data['gender'],
      'address': data['address'],
      'student_id': data['student_id'],
      'avatar': data['avatar'],
      'level_id': data['level_id'] ?? levels?['id'],
      'level_name': levels?['name'],
      'speciality_id': data['speciality_id'] ?? specialities?['id'],
      'speciality_name': specialities?['name'],
      'speciality_code': specialities?['code'],
      'phone_provider_name': phoneProviders?['name'],
      'phone_provider_code': phoneProviders?['code'],
      'social_media_links': data['social_media_links'],
    };
  }

  Future<void> syncFromAuth() async {
    final authUser = _ref.read(authProvider).user;
    if (authUser == null) return;
    final data = <String, dynamic>{
      'id': authUser.id,
      'email': authUser.email,
      'first_name': authUser.firstName,
      'last_name': authUser.lastName,
      'gender': authUser.gender,
      'student_id': authUser.studentId,
      'phone': authUser.phone,
      'level_id': authUser.levelId,
      'level_name': authUser.levelName,
      'speciality_id': authUser.specialityId,
      'speciality_name': authUser.specialityName,
      'roles': authUser.roles,
      'status': authUser.status,
    };
    await ProfileRepository.upsert(data);
    _profile = data;
    notifyListeners();
  }
}
