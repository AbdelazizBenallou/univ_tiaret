import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;

  AuthResponseModel({
    required this.success,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'],
      accessToken: json['access_token'] ?? json['data']?['access_token'],
      refreshToken: json['refresh_token'] ?? json['data']?['refresh_token'],
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : json['data']?['user'] != null
              ? UserModel.fromJson(json['data']['user'])
              : null,
    );
  }
}
