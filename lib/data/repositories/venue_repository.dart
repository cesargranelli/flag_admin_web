import 'package:flag_admin_web/data/services/venue_service.dart';
import 'package:flag_admin_web/domain/models/venue.dart';

/// Repositório de Praças Esportivas / Venues (ADR-001 - Cache TTL 60s).
class VenueRepository {
  final VenueService _service;

  VenueRepository({required VenueService service}) : _service = service;

  List<Venue>? _cached;
  DateTime? _lastFetch;
  static const Duration _cacheTtl = Duration(seconds: 60);

  Future<List<Venue>> getVenues({bool forceRefresh = false}) async {
    final isCacheValid = _cached != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return _cached!;
    }

    final data = await _service.list();
    _cached = List<Venue>.unmodifiable(data);
    _lastFetch = DateTime.now();
    return _cached!;
  }

  Future<Venue> createVenue({
    required String organizationId,
    required String name,
    String? address,
    String? mapsUrl,
  }) async {
    final created = await _service.create(
      organizationId: organizationId,
      name: name,
      address: address,
      mapsUrl: mapsUrl,
    );
    _cached = null;
    _lastFetch = null;
    return created;
  }

  Future<Venue> updateVenue(
    String id, {
    required String organizationId,
    required String name,
    String? address,
    String? mapsUrl,
  }) async {
    final updated = await _service.update(
      id,
      organizationId: organizationId,
      name: name,
      address: address,
      mapsUrl: mapsUrl,
    );
    _cached = null;
    _lastFetch = null;
    return updated;
  }
}
