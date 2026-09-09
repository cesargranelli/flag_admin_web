import 'package:flag_admin_web/data/services/venue_service.dart';
import 'package:flag_admin_web/domain/models/venue.dart';
import 'package:flag_admin_web/src/api/api_client.dart';
import 'package:flag_admin_web/src/api/services/venue_api.dart';

class ApiVenueService implements VenueService {
  final VenueApi _api;

  ApiVenueService(ApiClient client) : _api = VenueApi(client);

  @override
  Future<List<Venue>> list() => _api.list();

  @override
  Future<Venue> getById(String id) => _api.getById(id);
}
