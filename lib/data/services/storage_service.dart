import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Exceção lançada em caso de falha em operações de armazenamento.
class StorageServiceException implements Exception {
  final String message;
  final Object? cause;

  const StorageServiceException(this.message, [this.cause]);

  @override
  String toString() => 'StorageServiceException: $message';
}

/// Serviço de armazenamento de mídia e arquivos (ADR-001).
abstract class StorageService {
  /// Faz o upload de um logotipo de agremiação (instituição) e retorna a URL de download pública HTTPS.
  Future<String> uploadInstitutionLogo({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
    void Function(double progress)? onProgress,
  });

  /// Faz o upload de um logotipo de organização e retorna a URL de download pública HTTPS.
  Future<String> uploadOrganizationLogo({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
    void Function(double progress)? onProgress,
  });

  /// Tenta remover um arquivo previamente enviado através de sua URL pública.
  Future<void> deleteFileByUrl(String url);
}

/// Implementação do serviço de armazenamento utilizando o Firebase Storage.
class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService(this._storage);

  @override
  Future<String> uploadInstitutionLogo({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final sanitizedName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = 'institutions/logos/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      final ref = _storage.ref().child(path);

      final determinedMime = mimeType ?? _guessMimeType(filename);
      final metadata = SettableMetadata(
        contentType: determinedMime,
        cacheControl: 'public, max-age=31536000',
      );

      final uploadTask = ref.putData(bytes, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final total = snapshot.totalBytes;
          if (total > 0) {
            final progress = snapshot.bytesTransferred / total;
            onProgress(progress);
          }
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageServiceException(
        e.message ?? 'Falha ao realizar upload para o Firebase Storage.',
        e,
      );
    } catch (e) {
      throw StorageServiceException('Erro inesperado no upload da imagem: $e', e);
    }
  }

  @override
  Future<String> uploadOrganizationLogo({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final sanitizedName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = 'organizations/logos/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      final ref = _storage.ref().child(path);

      final determinedMime = mimeType ?? _guessMimeType(filename);
      final metadata = SettableMetadata(
        contentType: determinedMime,
        cacheControl: 'public, max-age=31536000',
      );

      final uploadTask = ref.putData(bytes, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final total = snapshot.totalBytes;
          if (total > 0) {
            final progress = snapshot.bytesTransferred / total;
            onProgress(progress);
          }
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageServiceException(
        e.message ?? 'Falha ao realizar upload para o Firebase Storage.',
        e,
      );
    } catch (e) {
      throw StorageServiceException('Erro inesperado no upload da imagem: $e', e);
    }
  }

  @override
  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Falha silenciosa ou log caso a imagem já tenha sido excluída ou não seja do bucket
    }
  }

  static String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'application/octet-stream';
  }
}
