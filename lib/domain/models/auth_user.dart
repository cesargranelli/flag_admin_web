import 'package:flag_admin_web/domain/enums/user_role.dart';
import 'package:flag_admin_web/domain/models/user.dart';

/// Modelo de domínio do usuário autenticado no Flag Platform (ADR-001).
class AuthUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? status;
  final String? organizationId;
  final String? clubId;
  final DateTime? createdAt;
  final String? token;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status,
    this.organizationId,
    this.clubId,
    this.createdAt,
    this.token,
  });

  /// Converte a partir do modelo legado [User] retornado pela API REST.
  factory AuthUser.fromUser(
    User user, {
    String? token,
    String? organizationId,
    String? clubId,
  }) {
    return AuthUser(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      status: user.status,
      organizationId: organizationId,
      clubId: clubId,
      createdAt: user.createdAt,
      token: token,
    );
  }

  /// Converte a partir de JSON recebido de /api/v1/auth/me ou de claims.
  factory AuthUser.fromJson(Map<String, dynamic> json, {String? token}) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] != null
          ? UserRole.fromJson(json['role'] as String)
          : UserRole.organizer,
      status: json['status'] as String?,
      organizationId: json['organizationId'] as String?,
      clubId: json['clubId'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      token: token,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.toJson(),
    if (status != null) 'status': status,
    if (organizationId != null) 'organizationId': organizationId,
    if (clubId != null) 'clubId': clubId,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  /// Converte para [User] legado para retrocompatibilidade em telas existentes.
  User toLegacyUser() {
    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      status: status,
      createdAt: createdAt,
    );
  }

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? status,
    String? organizationId,
    String? clubId,
    DateTime? createdAt,
    String? token,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      clubId: clubId ?? this.clubId,
      createdAt: createdAt ?? this.createdAt,
      token: token ?? this.token,
    );
  }
}
