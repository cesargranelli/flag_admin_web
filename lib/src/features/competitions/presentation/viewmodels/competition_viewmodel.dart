import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/competition_firestore_service.dart';
import '../domain/entities/competition.dart';

/// ViewModel para gerenciar estado das competições.
class CompetitionViewModel extends StateNotifier<AsyncValue<List<Competition>>> {
  final CompetitionFirestoreService _service;

  CompetitionViewModel(this._service) : super(const AsyncValue.loading()) {
    loadCompetitions();
  }

  /// Carrega todas as competições.
  Future<void> loadCompetitions() async {
    state = const AsyncValue.loading();
    try {
      final competitions = await _service.list();
      state = AsyncValue.data(competitions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Carrega competições por organização.
  Future<void> loadCompetitionsByOrganization(String organizationId) async {
    state = const AsyncValue.loading();
    try {
      final competitions = await _service.listByOrganization(organizationId);
      state = AsyncValue.data(competitions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Cria uma nova competição.
  Future<Competition?> createCompetition({
    required String organizationId,
    required String name,
    required String sport,
    String? seasonId,
    String? modality,
    String? gender,
    String? ageGroup,
  }) async {
    try {
      final competition = Competition(
        id: '',
        organizationId: organizationId,
        name: name,
        sport: sport,
        seasonId: seasonId,
        modality: modality,
        gender: gender,
        ageGroup: ageGroup,
        status: 'DRAFT',
        createdAt: DateTime.now(),
      );
      final created = await _service.create(competition);
      await loadCompetitions();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza uma competição existente.
  Future<void> updateCompetition(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(id, data);
      await loadCompetitions();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove uma competição.
  Future<void> deleteCompetition(String id) async {
    try {
      await _service.delete(id);
      await loadCompetitions();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider para o ViewModel de competições.
final competitionViewModelProvider =
    StateNotifierProvider<CompetitionViewModel, AsyncValue<List<Competition>>>(
  (ref) {
    final service = ref.watch(competitionFirestoreServiceProvider);
    return CompetitionViewModel(service);
  },
);

/// Provider para stream de competições.
final competitionStreamProvider = StreamProvider<List<Competition>>((ref) {
  final service = ref.watch(competitionFirestoreServiceProvider);
  return service.streamList();
});

