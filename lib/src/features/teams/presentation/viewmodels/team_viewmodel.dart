import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/team_firestore_service.dart';
import '../domain/entities/team.dart';

/// ViewModel para gerenciar estado dos times.
class TeamViewModel extends StateNotifier<AsyncValue<List<Team>>> {
  final TeamFirestoreService _service;

  TeamViewModel(this._service) : super(const AsyncValue.loading()) {
    loadTeams();
  }

  /// Carrega todos os times.
  Future<void> loadTeams() async {
    state = const AsyncValue.loading();
    try {
      final teams = await _service.list();
      state = AsyncValue.data(teams);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Carrega times por organização.
  Future<void> loadTeamsByOrganization(String organizationId) async {
    state = const AsyncValue.loading();
    try {
      final teams = await _service.listByOrganization(organizationId);
      state = AsyncValue.data(teams);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Cria um novo time.
  Future<Team?> createTeam({
    required String organizationId,
    required String name,
    String? shortName,
    String? logoUrl,
    String? sport,
  }) async {
    try {
      final team = Team(
        id: '',
        organizationId: organizationId,
        name: name,
        shortName: shortName,
        logoUrl: logoUrl,
        sport: sport,
        status: 'ACTIVE',
        createdAt: DateTime.now(),
      );
      final created = await _service.create(team);
      await loadTeams();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza um time existente.
  Future<void> updateTeam(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(id, data);
      await loadTeams();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove um time.
  Future<void> deleteTeam(String id) async {
    try {
      await _service.delete(id);
      await loadTeams();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider para o ViewModel de times.
final teamViewModelProvider =
    StateNotifierProvider<TeamViewModel, AsyncValue<List<Team>>>(
  (ref) {
    final service = ref.watch(teamFirestoreServiceProvider);
    return TeamViewModel(service);
  },
);

/// Provider para stream de times.
final teamStreamProvider = StreamProvider<List<Team>>((ref) {
  final service = ref.watch(teamFirestoreServiceProvider);
  return service.streamList();
});
