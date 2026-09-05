import 'package:flag_admin_web/src/domain/domain.dart';

import '../datasources/organization_firestore_service.dart';

/// Repository para organizações.
///
/// Abstrai a fonte de dados (Firestore — leitura realtime, espelho ADR-006)
/// da lógica de negócio, operando sobre o [Organization] de domínio.
///
/// A escrita NÃO deve passar por aqui em produção: permanece 100% via REST
/// (issue #52), com o Firestore como espelho gravado pelo backend.
class OrganizationRepository {
  final OrganizationFirestoreService _datasource;

  OrganizationRepository(this._datasource);

  /// Lista todas as organizações (sem filtro de visibilidade).
  Future<List<Organization>> getAll() async {
    return await _datasource.list();
  }

  /// Busca organização por ID.
  Future<Organization?> getById(String id) async {
    return await _datasource.getById(id);
  }

  /// Cria nova organização.
  Future<Organization> create(Organization organization) async {
    return await _datasource.create(organization);
  }

  /// Atualiza organização existente.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _datasource.update(id, data);
  }

  /// Remove organização.
  Future<void> delete(String id) async {
    await _datasource.delete(id);
  }

  /// Escuta todas as organizações em tempo real (sem filtro de visibilidade).
  Stream<List<Organization>> watchAll() {
    return _datasource.streamList();
  }

  /// Escuta apenas as organizações ATIVAS (decisão de visibilidade #52).
  Stream<List<Organization>> watchActive() {
    return _datasource.streamActive();
  }
}
