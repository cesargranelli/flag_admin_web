import 'package:flag_admin_web/domain/models/venue.dart';

abstract class VenueService {
  Future<List<Venue>> list();
  Future<Venue> getById(String id);
  Future<Venue> create({
    required String organizationId,
    required String name,
    String? address,
    String? mapsUrl,
  });
  Future<Venue> update(
    String id, {
    required String organizationId,
    required String name,
    String? address,
    String? mapsUrl,
  });
}
