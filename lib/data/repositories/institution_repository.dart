import 'package:flag_admin_web/domain/models/institution.dart';
import '../services/institution_service.dart';

/// Repository de agremiações (camada Repositories - ADR-001).
///
/// Single Source of Truth para clubes e universidades.
class InstitutionRepository {
  final InstitutionService _service;

  InstitutionRepository({required InstitutionService service})
      : _service = service;

  List<Institution>? _cache;

  /// Retorna a lista de agremiações com suporte a cache em memória.
  Future<List<Institution>> getInstitutions({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      return _cache!;
    }
    final data = await _service.getInstitutions();
    _cache = List<Institution>.unmodifiable(data);
    return _cache!;
  }

  /// Busca uma agremiação por ID.
  Future<Institution> getInstitution(String id) async {
    if (_cache != null) {
      final match = _cache!.where((i) => i.id == id);
      if (match.isNotEmpty) return match.first;
    }
    return _service.getInstitution(id);
  }

  /// Cria nova agremiação e invalida o cache.
  Future<Institution> createInstitution(Map<String, dynamic> body) async {
    final created = await _service.createInstitution(body);
    clearCache();
    return created;
  }

  /// Atualiza agremiação existente e invalida o cache.
  Future<Institution> updateInstitution(
    String id,
    Map<String, dynamic> body,
  ) async {
    final updated = await _service.updateInstitution(id, body);
    clearCache();
    return updated;
  }

  /// Exclui agremiação e invalida o cache.
  Future<void> deleteInstitution(String id) async {
    await _service.deleteInstitution(id);
    clearCache();
  }

  /// Atualiza a filiação a organizações (N:N) e invalida o cache.
  Future<void> updateOrganizations(String id, List<String> orgIds) async {
    await _service.updateOrganizations(id, orgIds);
    clearCache();
  }

  /// Limpa o cache local.
  void clearCache() {
    _cache = null;
  }
}
