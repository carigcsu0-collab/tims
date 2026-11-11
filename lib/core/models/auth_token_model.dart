import 'package:equatable/equatable.dart';

import 'package:tims/core/models/user_model.dart';

/// Represents the authentication response containing tokens and user data.
class AuthTokenModel extends Equatable {
  const AuthTokenModel({
    required this.accessToken,
    required this.tokenType,
    required this.user,
    this.refreshToken,
    this.expiresIn,
  });

  final String accessToken;
  final String tokenType;
  final UserModel user;
  final String? refreshToken;
  final int? expiresIn;

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    return AuthTokenModel(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'token_type': tokenType,
        'user': user.toJson(),
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
      };

  @override
  List<Object?> get props => [accessToken, tokenType, user, refreshToken, expiresIn];
}
