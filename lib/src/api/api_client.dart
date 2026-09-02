import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flag_admin_web/src/core/flag_core.dart';

import 'repository_exception.dart';

/// Cliente HTTP da API REST do Flag Platform.
///
/// Usa [AppConfig.apiBaseUrl] como base URL e injeta o token JWT via
/// [SessionManager] quando autenticado.
class ApiClient {
  final Dio dio;
  final SessionManager _session;

  ApiClient({
    required SessionManager session,
    Dio? dio,
  })  : _session = session,
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Accept': 'application/json'},
              ),
            );

  ApiClient get public => this;

  Future<Map<String, dynamic>> _headers() async {
    final token = await _session.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<T>> getList<T>(String path, T Function(Map<String, dynamic>) fromJson) async {
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

  Future<T> getOne<T>(String path, T Function(Map<String, dynamic>) fromJson) async {
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

  /// Faz upload de bytes (imagem) via multipart POST e retorna a URL
  /// pública do arquivo salvo pelo backend.
  ///
  /// No Flutter Web, `file_picker` retorna bytes (Uint8List), não caminhos
  /// locais — por isso o método aceita bytes diretamente.
  Future<String> uploadBytes(
    Uint8List bytes,
    String filename, {
    String fieldName = 'file',
  }) async {
    try {
      final headers = await _headers();
      // Remove Content-Type para que Dio defina o boundary do multipart.
      headers.remove('Content-Type');

      final formData = FormData.fromMap({
        fieldName: MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/upload',
        data: formData,
        options: Options(headers: headers),
      );
      // A API retorna URL relativa (ex.: /api/v1/uploads/arquivo.jpg).
      // Converter para URL absoluta para Image.network funcionar no Flutter
      // Web (que roda em porta diferente da API).
      final url = response.data!['url'] as String;
      if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
      return url;
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
