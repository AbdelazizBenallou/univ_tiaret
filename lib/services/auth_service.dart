import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:univ_tiaret/models/user_model.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';
  static const _deviceFingerprintKey = 'device_fingerprint';

  static Future<String> getDeviceFingerprint() async {
    final existing = await _storage.read(key: _deviceFingerprintKey);
    if (existing != null) return existing;

    final deviceInfo = DeviceInfoPlugin();
    String identifier = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      identifier = '${androidInfo.id}${androidInfo.brand}${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      identifier = '${iosInfo.identifierForVendor}${iosInfo.name}${iosInfo.model}';
    } else {
      identifier = 'web-${DateTime.now().millisecondsSinceEpoch}';
    }

    final bytes = utf8.encode(identifier);
    final fingerprint = sha256.convert(bytes).toString();
    await _storage.write(key: _deviceFingerprintKey, value: fingerprint);
    return fingerprint;
  }

  static Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return '${info.brand} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return '${info.name} ${info.model}';
    }
    return 'Unknown Device';
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  static Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  static Future<UserModel?> getUser() async {
    final data = await _storage.read(key: _userKey);
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  static Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  static String detectUserState(Map<String, dynamic> response) {
    final message = (response['message'] ?? '').toString().toLowerCase();
    final status = (response['status'] ?? '').toString().toLowerCase();

    if (status == 'pending') return 'pending';
    if (status == 'active') return 'active';

    if (message.contains('not active') ||
        message.contains('not verified') ||
        message.contains('email not verified')) {
      return 'pending';
    }
    if (message.contains('device') && message.contains('not recognized')) {
      return 'wrong_device';
    }
    if (message.contains('device') &&
        (message.contains('occupied') || message.contains('already registered'))) {
      return 'device_occupied';
    }
    return 'unknown';
  }
}
