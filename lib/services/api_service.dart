import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:univ_tiaret/services/auth_service.dart';

class ApiService {
  static String _baseUrl = "http://localhost:3000";
  static bool _initialized = false;
  static Completer<bool>? _refreshCompleter;

  static const _authEndpoints = [
    '/v1/auth/login',
    '/v1/auth/register',
    '/v1/auth/refresh-token',
    '/v1/auth/forgot-password',
    '/v1/auth/reset-password',
    '/v1/auth/verify-email',
    '/v1/auth/resend-code',
    '/health',
  ];

  static String get baseUrl => _baseUrl;

  static void initialize(String url) {
    _baseUrl = url;
    _initialized = true;
  }

  static bool get isInitialized => _initialized;

  static bool _isAuthEndpoint(String endpoint) {
    return _authEndpoints.any((e) => endpoint.startsWith(e));
  }

  static Future<Map<String, String>> _headers({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth) {
      final token = await AuthService.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool includeAuth = true,
    int maxRetries = 2,
  }) async {
    return _requestWithRetry(
      method: 'GET',
      endpoint: endpoint,
      includeAuth: includeAuth,
      maxRetries: maxRetries,
    );
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    int maxRetries = 2,
  }) async {
    return _requestWithRetry(
      method: 'PATCH',
      endpoint: endpoint,
      body: body,
      includeAuth: includeAuth,
      maxRetries: maxRetries,
    );
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    int maxRetries = 2,
  }) async {
    return _requestWithRetry(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      includeAuth: includeAuth,
      maxRetries: maxRetries,
    );
  }

  static Future<Map<String, dynamic>> _requestWithRetry({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool includeAuth = true,
    int maxRetries = 2,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        final uri = Uri.parse('$_baseUrl$endpoint');
        final headers = await _headers(includeAuth: includeAuth);

        http.Response response;
        if (method == 'GET') {
          response = await http.get(uri, headers: headers).timeout(
                const Duration(seconds: 10),
              );
        } else if (method == 'PATCH') {
          response = await http
              .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 10));
        } else {
          response = await http
              .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 10));
        }

        // 401 on auth endpoints -> parse server message (login/register errors)
        if (response.statusCode == 401 && _isAuthEndpoint(endpoint)) {
          try {
            final data = jsonDecode(response.body);
            return {'success': false, 'message': data['message'] ?? 'Invalid credentials'};
          } catch (_) {
            return {'success': false, 'message': 'Invalid credentials'};
          }
        }

        // 401 on non-auth endpoints -> parse server message first
        if (response.statusCode == 401 && !_isAuthEndpoint(endpoint)) {
          try {
            final data = jsonDecode(response.body);
            final message = data['message'] ?? 'Session expired';
            // If server says unauthorized/token expired, try refresh
            final msg = message.toLowerCase();
            if (msg.contains('unauthorized') ||
                msg.contains('token') ||
                msg.contains('expired') ||
                msg.contains('invalid token')) {
              final refreshed = await _tryRefreshTokenDedup();
              if (refreshed) {
                continue;
              }
              await AuthService.clearAuth();
              return {'success': false, 'message': 'Session expired'};
            }
            // Other 401s (e.g. "Invalid current password") -> show server message
            return {'success': false, 'message': message};
          } catch (_) {}
          final refreshed = await _tryRefreshTokenDedup();
          if (refreshed) {
            continue;
          }
          await AuthService.clearAuth();
          return {'success': false, 'message': 'Session expired'};
        }

        // 409 conflict (register: email already exists with status)
        if (response.statusCode == 409) {
          try {
            final data = jsonDecode(response.body);
            return data;
          } catch (_) {
            return {'success': false, 'message': 'Conflict'};
          }
        }

        return _handleResponse(response);
      } on TimeoutException {
        if (attempt < maxRetries) {
          attempt++;
          await Future.delayed(Duration(seconds: 1 * (1 << attempt)));
          continue;
        }
        return {'success': false, 'message': 'Network timeout'};
      } catch (e) {
        if (attempt < maxRetries) {
          attempt++;
          await Future.delayed(Duration(seconds: 1 * (1 << attempt)));
          continue;
        }
        return {'success': false, 'message': 'Network error: $e'};
      }
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) {
      return {'success': true};
    }

    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': response.body,
      };
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsed;
    }

    return {
      'success': false,
      'message': parsed['message'] ?? parsed['error'] ?? 'Request failed',
    };
  }

  /// Concurrent refresh dedup: only one refresh request, others wait
  static Future<bool> _tryRefreshTokenDedup() async {
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final result = await _tryRefreshToken();
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(result);
      }
      return result;
    } catch (e) {
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  static Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await AuthService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/v1/auth/refresh-token'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Server returns: { success, data: { accessToken } }
          final newAccessToken = data['data']?['accessToken'];
          if (newAccessToken != null) {
            await AuthService.saveTokens(
              accessToken: newAccessToken,
              refreshToken: refreshToken,
            );
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Extract nested token/user from server response.
  /// Server format: { success, data: { accessToken, refreshToken, user } }
  static Map<String, dynamic> extractAuthData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return {
        'accessToken': data['accessToken'],
        'refreshToken': data['refreshToken'],
        'user': data['user'],
      };
    }
    // Fallback: check top-level (for older response formats)
    return {
      'accessToken': response['accessToken'] ?? response['access_token'],
      'refreshToken': response['refreshToken'] ?? response['refresh_token'],
      'user': response['user'],
    };
  }

  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // Server returns { status: "ok" }
          if (data['status'] == 'ok') {
            return {'success': true};
          }
          return data;
        } catch (_) {
          return {'success': true};
        }
      }
      return {'success': false, 'message': 'Server responded with ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Server unreachable'};
    }
  }
}
