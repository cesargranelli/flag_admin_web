import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/organization_firestore_service.dart';
import '../domain/entities/organization.dart';

/// ViewModel para gerenciar estado das organizações.
///
/// Usa Riverpod para gerenciamento de estado reativo.
class OrganizationViewModel extends StateNotifier<AsyncValue<List<Organization>>> {
  final OrganizationFirestoreService _service;

  OrganizationViewModel(this._service) : super(const AsyncValue.loading()) {
    loadOrganizations();
  }

  /// Carrega todas as organizações.
  Future<void> loadOrganizations() async {
    state = const AsyncValue.loading();
    try {
      final organizations = await _service.list();
      state = AsyncValue.data(organizations);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Cria uma nova organização.
  Future<Organization?> createOrganization({
    required String name,
    String? tradeName,
    String? type,
    String? document,
  }) async {
    try {
      final organization = Organization(
        id: '',
        name: name,
        tradeName: tradeName,
        type: type,
        document: document,
        status: 'ACTIVE',
        createdAt: DateTime.now(),
      );
      final created = await _service.create(organization);
      await loadOrganizations(); // Recarrega a lista
      return created;
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza uma organização existente.
  Future<void> updateOrganization(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(id, data);
      await loadOrganizations(); // Recarrega a lista
    } catch (e) {
      rethrow;
    }
  }

  /// Remove uma organização.
  Future<void> deleteOrganization(String id) async {
    try {
      await _service.delete(id);
      await loadOrganizations(); // Recarrega a lista
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider para o ViewModel de organizações.
final organizationViewModelProvider =
    StateNotifierProvider<OrganizationViewModel, AsyncValue<List<Organization>>>(
  (ref) {
    final service = ref.watch(organizationFirestoreServiceProvider);
    return OrganizationViewModel(service);
  },
);

/// Provider para stream de organizações.
final organizationStreamProvider = StreamProvider<List<Organization>>((ref) {
  final service = ref.watch(organizationFirestoreServiceProvider);
  return service.streamList();
});
