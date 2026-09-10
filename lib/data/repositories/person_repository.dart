import 'package:flag_admin_web/domain/models/person.dart';
import 'package:flag_admin_web/domain/models/person_batch.dart';
import '../services/person_service.dart';

/// Repository de pessoas (camada Repositories - ADR-001).
///
/// Single Source of Truth para pessoas com cache em memoria TTL 30s.
class PersonRepository {
  final PersonService _service;

  PersonRepository({required PersonService service})
      : _service = service;

  List<Person>? _cache;
  DateTime? _lastFetch;
  static const Duration _cacheTtl = Duration(seconds: 30);

  /// Retorna a lista de pessoas com suporte a cache em memoria com TTL de 30s.
  Future<List<Person>> getPersons({bool forceRefresh = false}) async {
    final isCacheValid = _cache != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return _cache!;
    }
    final data = await _service.getPersons();
    _cache = List<Person>.unmodifiable(data);
    _lastFetch = DateTime.now();
    return _cache!;
  }

  /// Busca uma pessoa por ID.
  Future<Person> getPerson(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      final match = _cache!.where((p) => p.id == id);
      if (match.isNotEmpty) return match.first;
    }
    return _service.getPerson(id);
  }

  /// Cria nova pessoa e invalida o cache.
  Future<Person> createPerson(Map<String, dynamic> body) async {
    final created = await _service.createPerson(body);
    clearCache();
    return created;
  }

  /// Atualiza pessoa existente e invalida o cache.
  Future<Person> updatePerson(String id, Map<String, dynamic> body) async {
    final updated = await _service.updatePerson(id, body);
    clearCache();
    return updated;
  }

  /// Valida uma carga em lote de pessoas (dry-run).
  Future<PersonBatchResult> validateBatch(List<Map<String, dynamic>> items) =>
      _service.validateBatch(items);

  /// Importa uma carga em lote de pessoas e invalida o cache.
  Future<PersonBatchResult> createBatch(List<Map<String, dynamic>> items) async {
    final result = await _service.createBatch(items);
    clearCache();
    return result;
  }

  /// Limpa o cache local.
  void clearCache() {
    _cache = null;
    _lastFetch = null;
  }
}
