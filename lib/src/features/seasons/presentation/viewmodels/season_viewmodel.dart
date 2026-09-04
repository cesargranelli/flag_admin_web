import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/season_firestore_service.dart';
import '../domain/entities/season.dart';

/// ViewModel para gerenciar estado das temporadas.
class SeasonViewModel extends StateNotifier<AsyncValue<List<Season>>> {
  final SeasonFirestoreService _service;

  SeasonViewModel(this._service) : super(const AsyncValue.loading()) {
    loadSeasons();
  }

  /// Carrega todas as temporadas.
  Future<void> loadSeasons() async {
    state = const AsyncValue.loading();
    try {
      final seasons = await _service.list();
      state = AsyncValue.data(seasons);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Carrega temporadas por organização.
  Future<void> loadSeasonsByOrganization(String organizationId) async {
    state = const AsyncValue.loading();
    try {
      final seasons = await _service.listByOrganization(organizationId);
      state = AsyncValue.data(seasons);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Cria uma nova temporada.
  Future<Season?> createSeason({
    required String organizationId,
    required String name,
    required String sport,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final season = Season(
        id: '',
        organizationId: organizationId,
        name: name,
        sport: sport,
        startDate: startDate,
        endDate: endDate,
        status: 'DRAFT',
        createdAt: DateTime.now(),
      );
      final created = await _service.create(season);
      await loadSeasons();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza uma temporada existente.
  Future<void> updateSeason(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(id, data);
      await loadSeasons();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove uma temporada.
  Future<void> deleteSeason(String id) async {
    try {
      await _service.delete(id);
      await loadSeasons();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider para o ViewModel de temporadas.
final seasonViewModelProvider =
    StateNotifierProvider<SeasonViewModel, AsyncValue<List<Season>>>(
  (ref) {
    final service = ref.watch(seasonFirestoreServiceProvider);
    return SeasonViewModel(service);
  },
);

/// Provider para stream de temporadas.
final seasonStreamProvider = StreamProvider<List<Season>>((ref) {
  final service = ref.watch(seasonFirestoreServiceProvider);
  return service.streamList();
});
