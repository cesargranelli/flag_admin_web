import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flag_admin_web/data/session/session_manager.dart';
import 'package:flag_admin_web/config/core_imports.dart';

import 'repository_exception.dart';

/// Cliente HTTP da API REST do Flag Platform.
///
/// Usa [AppConfig.apiBaseUrl] como base URL e injeta o Firebase ID Token
/// via [FirebaseAuth] quando autenticado (Migração Firebase Auth #33).
class ApiClient {
  final Dio dio;

  final SessionManager? _sessionManager;

  ApiClient({Dio? dio, SessionManager? sessionManager})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/json'},
            ),
          ),
      _sessionManager = sessionManager;

  ApiClient get public => this;

  /// Retorna os headers HTTP, priorizando o token JWT nativo do backend
  /// salvo na sessão, ou alternativamente o Firebase ID Token.
  Future<Map<String, dynamic>> _headers() async {
    String? token;

    // 1. Tenta recuperar o token nativo do backend persistido na sessão
    try {
      token = await _sessionManager?.getToken();
    } catch (_) {
      // Ignora erro de leitura local
    }

    // 2. Se não houver token nativo, tenta o Firebase ID Token
    if (token == null || token.isEmpty) {
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (_) {
        // Firebase não disponível (ex: em testes)
      }
    }

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<T>> getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await dio.get<List<dynamic>>(
        path,
        options: Options(headers: await _headers()),
      );
      return (response.data ?? const [])
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }

  Future<T> getOne<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: await _headers()),
      );
      return fromJson(response.data!);
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }

  Future<T> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: await _headers()),
      );
      return fromJson(response.data!);
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }

  Future<T> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: await _headers()),
      );
      return fromJson(response.data!);
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }

  Future<T> patch<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: await _headers()),
      );
      return fromJson(response.data!);
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await dio.delete<void>(path, options: Options(headers: await _headers()));
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }
}
