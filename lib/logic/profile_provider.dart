import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/db/db.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/services/api_service.dart';

List<Map<String, dynamic>> parseSocialLinks(dynamic raw) {
  if (raw == null) return const [];
  dynamic data = raw;
  if (raw is String) {
    try {
      data = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
  }
  if (data is List) {
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

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
      debugPrint('[Profile] Loaded cached profile: '
          'name=${_profile!['first_name']} ${_profile!['last_name']}');
    }

    try {
      debugPrint('[Profile] Fetching GET /v1/users/me/profile');
      final response = await ApiService.get('/v1/users/me/profile');
      if (response['success'] == true &&
          response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        _profile = _normalize(data);
        await ProfileRepository.upsert(_profile!);
        debugPrint('[Profile] Profile loaded OK: '
            'name=${_profile!['first_name']} ${_profile!['last_name']}, '
            'avatar=${_profile!['avatar']}, '
            'social_media=${_profile!['social_media_links']}');
      } else {
        final message =
            response['message'] as String? ?? 'Failed to load profile';
        debugPrint(
          'Profile load failed: $message (${response['errors'] ?? response})',
        );
        _error = message;
        if (_profile == null) await syncFromAuth();
      }
    } catch (e, st) {
      debugPrint('Profile load error: $e\n$st');
      _error = 'err_network';
      if (_profile == null) {
        await syncFromAuth();
        if (_profile != null) _error = null;
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<String?> update(Map<String, dynamic> fields) async {
    _saving = true;
    notifyListeners();
    debugPrint('[Profile] PATCH /v1/users/me/profile fields=$fields');

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
        await _ref
            .read(authProvider.notifier)
            .syncUserFromProfile(Map<String, dynamic>.from(fields));
        _saving = false;
        notifyListeners();
        debugPrint('[Profile] Profile updated successfully');
        return null;
      }

      _saving = false;
      notifyListeners();
      final message = response['message'] as String? ?? 'Update failed';
      debugPrint(
        '[Profile] Update FAILED: $message (${response['errors'] ?? response})',
      );
      return message;
    } catch (e, st) {
      debugPrint('[Profile] Update EXCEPTION: $e\n$st');
      _saving = false;
      notifyListeners();
      return 'err_network';
    }
  }

  /// Upload a new avatar image. Returns the server file id + error message.
  Future<({String? id, String? error})> uploadAvatar(
    Uint8List bytes,
    String filename,
  ) async {
    debugPrint('[Profile] Uploading avatar: $filename, ${bytes.length} bytes');
    try {
      final response = await ApiService.uploadFiles(
        '/v1/files/upload?category=avatar',
        bytes: bytes,
        filename: filename,
      );
      if (response['success'] != true) {
        final message =
            response['message'] as String? ?? 'Upload failed';
        debugPrint('[Profile] Upload FAILED: $message');
        return (id: null, error: message);
      }
      final data = response['data'];
      final id = data is List && data.isNotEmpty
          ? (data.first as Map<String, dynamic>)['id']
          : null;
      if (id == null) {
        debugPrint('[Profile] Upload FAILED: no file id in response: $data');
        return (id: null, error: 'Upload failed');
      }
      debugPrint('[Profile] Upload SUCCESS: file id=$id');
      return (id: id.toString(), error: null);
    } catch (e, st) {
      debugPrint('[Profile] Upload EXCEPTION: $e\n$st');
      return (id: null, error: 'err_network');
    }
  }

  /// Builds a displayable URL for the avatar from its stored value.
  /// Accepts a file id ("2"), a path ("/v1/files/2/download") or a full URL.
  String? avatarUrlOf(String? avatar) {
    if (avatar == null || avatar.isEmpty) return null;
    if (avatar.startsWith('http')) return avatar;
    if (avatar.startsWith('/')) return '${ApiService.baseUrl}$avatar';
    if (int.tryParse(avatar) != null) {
      return '${ApiService.baseUrl}/v1/files/$avatar/download';
    }
    return avatar;
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> data) {
    final authUser = _ref.read(authProvider).user;
    final nested = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data['profile'] is Map<String, dynamic>
            ? data['profile'] as Map<String, dynamic>
            : null;
    final levels =
        (data['levels'] ?? data['level']) as Map<String, dynamic>?;
    final specialities =
        (data['specialities'] ?? data['speciality']) as Map<String, dynamic>?;
    final phoneProviders = data['phone_providers'] as Map<String, dynamic>?;

    String? pick(String key, String? fallback) {
      final direct = data[key];
      if (direct != null && direct.toString().isNotEmpty) {
        return direct.toString();
      }
      final inNested = nested?[key];
      if (inNested != null && inNested.toString().isNotEmpty) {
        return inNested.toString();
      }
      return fallback;
    }

    String? pickNested(String key) {
      final direct = data[key];
      if (direct != null && direct.toString().isNotEmpty) {
        return direct.toString();
      }
      return null;
    }

    return {
      'id': data['id'] ?? nested?['id'] ?? authUser?.id,
      'user_id': data['user_id'] ?? nested?['user_id'],
      'email': pick('email', authUser?.email),
      'first_name': pick('first_name', authUser?.firstName),
      'last_name': pick('last_name', authUser?.lastName),
      'phone': pick('phone', authUser?.phone),
      'phone_provider_id': data['phone_provider_id'],
      'date_of_birth': data['date_of_birth'],
      'gender': pick('gender', authUser?.gender),
      'address': data['address'],
      'student_id': pick('student_id', authUser?.studentId),
      'avatar': pick('avatar', authUser?.avatar),
      'level_id': data['level_id'] ?? levels?['id'] ?? authUser?.levelId,
      'level_name': levels?['name'] ?? pickNested('level_name') ?? authUser?.levelName,
      'speciality_id': data['speciality_id'] ?? specialities?['id'] ?? authUser?.specialityId,
      'speciality_name': specialities?['name'] ?? pickNested('speciality_name') ?? authUser?.specialityName,
      'speciality_code': specialities?['code'] ?? pickNested('speciality_code'),
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
      'avatar': authUser.avatar,
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
