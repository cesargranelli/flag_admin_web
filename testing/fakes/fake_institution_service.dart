import 'package:flag_admin_web/data/services/institution_service.dart';
import 'package:flag_admin_web/domain/models/institution.dart';

/// Implementação Fake em memória de [InstitutionService] para testes.
class FakeInstitutionService implements InstitutionService {
  final List<Institution> institutions;
  bool shouldThrow = false;
  String? errorMessage;
  int getInstitutionsCallCount = 0;
  int deleteCallCount = 0;
  int updateOrganizationsCallCount = 0;

  FakeInstitutionService({List<Institution>? initial})
      : institutions = initial != null ? List.from(initial) : [];

  @override
  Future<List<Institution>> getInstitutions() async {
    getInstitutionsCallCount++;
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro de rede simulado');
    }
    return List.from(institutions);
  }

  @override
  Future<Institution> getInstitution(String id) async {
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro ao buscar agremiação');
    }
    final match = institutions.where((i) => i.id == id);
    if (match.isEmpty) {
      throw Exception('Agremiação não encontrada: $id');
    }
    return match.first;
  }

  @override
  Future<Institution> createInstitution(Map<String, dynamic> body) async {
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro ao criar agremiação');
    }
    final inst = Institution(
      id: 'inst-${institutions.length + 1}',
      name: body['name'] as String,
      type: InstitutionType.fromJson(body['type'] as String),
      colors: (body['colors'] as List?)?.cast<String>() ?? const [],
      organizations: (body['organizations'] as List?)?.cast<String>() ?? const [],
    );
    institutions.add(inst);
    return inst;
  }

  @override
  Future<Institution> updateInstitution(String id, Map<String, dynamic> body) async {
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro ao atualizar agremiação');
    }
    final index = institutions.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw Exception('Agremiação não encontrada: $id');
    }
    final existing = institutions[index];
    final updated = Institution(
      id: existing.id,
      name: body['name'] as String? ?? existing.name,
      type: body['type'] != null
          ? InstitutionType.fromJson(body['type'] as String)
          : existing.type,
      colors: body['colors'] != null
          ? (body['colors'] as List).cast<String>()
          : existing.colors,
      organizations: body['organizations'] != null
          ? (body['organizations'] as List).cast<String>()
          : existing.organizations,
      status: existing.status,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    institutions[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteInstitution(String id) async {
    deleteCallCount++;
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro ao excluir agremiação');
    }
    institutions.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> updateOrganizations(String id, List<String> orgIds) async {
    updateOrganizationsCallCount++;
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro ao vincular organizações');
    }
    final index = institutions.indexWhere((i) => i.id == id);
    if (index != -1) {
      final existing = institutions[index];
      institutions[index] = Institution(
        id: existing.id,
        name: existing.name,
        type: existing.type,
        colors: existing.colors,
        organizations: List.from(orgIds),
        status: existing.status,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }
}

Institution createTestInstitution({
  String id = 'inst-1',
  String name = 'Clube Teste',
  InstitutionType type = InstitutionType.club,
  List<String> colors = const ['#FF0000'],
  List<String> organizations = const [],
}) {
  return Institution(
    id: id,
    name: name,
    type: type,
    colors: colors,
    organizations: organizations,
  );
}
