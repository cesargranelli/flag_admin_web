import 'package:flag_admin_web/data/services/venue_service.dart';
import 'package:flag_admin_web/domain/models/venue.dart';
import 'package:flag_admin_web/data/api/api_client.dart';
import 'package:flag_admin_web/data/api/services/venue_api.dart';

class ApiVenueService implements VenueService {
  final VenueApi _api;

  ApiVenueService(ApiClient client) : _api = VenueApi(client);

  @override
  Future<List<Venue>> list() => _api.list();

  @override
  Future<Venue> getById(String id) => _api.getById(id);

  @override
  Future<Venue> create({
    required String organizationId,
    required String name,
    String? address,
    String? mapsUrl,
  }) =>
      _api.create(
        organizationId: organizationId,
        name: name,
        address: address,
        mapsUrl: mapsUrl,
      );

  @override
  Future<Venue> update(
    String id, {
    required String organizationId,
    required String name,
    String? address,
    String? mapsUrl,
  }) =>
      _api.update(
        id,
        organizationId: organizationId,
        name: name,
        address: address,
        mapsUrl: mapsUrl,
      );
}
