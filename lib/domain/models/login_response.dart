import 'package:flag_admin_web/domain/models/user.dart';

/// Resposta da autenticação retornada por POST /api/v1/auth/login.
class LoginResponse {
  final String token;
  final String tokenType;
  final int expiresInSeconds;
  final User user;

  const LoginResponse({
    required this.token,
    required this.tokenType,
    required this.expiresInSeconds,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    token: json['token'] as String,
    tokenType: (json['tokenType'] as String?) ?? 'Bearer',
    expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 3600,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'tokenType': tokenType,
    'expiresInSeconds': expiresInSeconds,
    'user': user.toJson(),
  };
}
