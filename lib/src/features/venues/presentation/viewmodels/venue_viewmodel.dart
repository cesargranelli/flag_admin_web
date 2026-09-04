import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/venue_firestore_service.dart';
import '../domain/entities/venue.dart';

/// ViewModel para gerenciar estado dos venues.
class VenueViewModel extends StateNotifier<AsyncValue<List<Venue>>> {
  final VenueFirestoreService _service;

  VenueViewModel(this._service) : super(const AsyncValue.loading()) {
    loadVenues();
  }

  /// Carrega todos os venues.
  Future<void> loadVenues() async {
    state = const AsyncValue.loading();
    try {
      final venues = await _service.list();
      state = AsyncValue.data(venues);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Cria um novo venue.
  Future<Venue?> createVenue({
    required String name,
    String? logoUrl,
    Map<String, dynamic>? address,
    String? mapsUrl,
  }) async {
    try {
      final venue = Venue(
        id: '',
        name: name,
        logoUrl: logoUrl,
        address: address,
        mapsUrl: mapsUrl,
        createdAt: DateTime.now(),
      );
      final created = await _service.create(venue);
      await loadVenues();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza um venue existente.
  Future<void> updateVenue(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(id, data);
      await loadVenues();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove um venue.
  Future<void> deleteVenue(String id) async {
    try {
      await _service.delete(id);
      await loadVenues();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider para o ViewModel de venues.
final venueViewModelProvider =
    StateNotifierProvider<VenueViewModel, AsyncValue<List<Venue>>>(
  (ref) {
    final service = ref.watch(venueFirestoreServiceProvider);
    return VenueViewModel(service);
  },
);

/// Provider para stream de venues.
final venueStreamProvider = StreamProvider<List<Venue>>((ref) {
  final service = ref.watch(venueFirestoreServiceProvider);
  return service.streamList();
});
