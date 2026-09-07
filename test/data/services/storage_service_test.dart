import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/data/services/storage_service.dart';

class FakeStorageService implements StorageService {
  String? lastUploadedFilename;
  Uint8List? lastUploadedBytes;
  String? lastDeletedUrl;

  @override
  Future<String> uploadOrganizationLogo({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    lastUploadedFilename = filename;
    lastUploadedBytes = bytes;
    onProgress?.call(0.5);
    onProgress?.call(1.0);
    return 'https://firebasestorage.googleapis.com/v0/b/flag-platform.firebasestorage.app/o/organizations%2Flogos%2Ftest.png?alt=media';
  }

  @override
  Future<void> deleteFileByUrl(String url) async {
    lastDeletedUrl = url;
  }
}

void main() {
  group('StorageService & Color Validation Tests', () {
    late FakeStorageService service;

    setUp(() {
      service = FakeStorageService();
    });

    test('FakeStorageService realiza upload e retorna URL pública do Firebase', () async {
      double? reportedProgress;
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final url = await service.uploadOrganizationLogo(
        bytes: bytes,
        filename: 'meu_logo.png',
        onProgress: (p) => reportedProgress = p,
      );

      expect(url, contains('firebasestorage.googleapis.com'));
      expect(service.lastUploadedFilename, equals('meu_logo.png'));
      expect(service.lastUploadedBytes, equals(bytes));
      expect(reportedProgress, equals(1.0));
    });

    test('Validação de regex de cores hexadecimais aceita formatos válidos', () {
      final hexRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');

      expect(hexRegex.hasMatch('#FD6B22'), isTrue);
      expect(hexRegex.hasMatch('#FFFFFF'), isTrue);
      expect(hexRegex.hasMatch('#000000'), isTrue);
      expect(hexRegex.hasMatch('#1877F2'), isTrue);
      expect(hexRegex.hasMatch('#00b14f'), isTrue);

      // Casos que não devem casar
      expect(hexRegex.hasMatch('FD6B22'), isFalse);
      expect(hexRegex.hasMatch(r'#FD6B22$'), isFalse);
      expect(hexRegex.hasMatch('#12345'), isFalse);
      expect(hexRegex.hasMatch('#1234567'), isFalse);
      expect(hexRegex.hasMatch('#ZZZZZZ'), isFalse);
    });

    test('Normalização de código de cor com prefixo #', () {
      String normalizeColor(String raw) {
        var t = raw.trim().toUpperCase();
        if (t.isNotEmpty && !t.startsWith('#')) {
          t = '#$t';
        }
        return t;
      }

      expect(normalizeColor('fd6b22'), equals('#FD6B22'));
      expect(normalizeColor('#1877f2'), equals('#1877F2'));
      expect(normalizeColor(''), equals(''));
    });
  });
}
