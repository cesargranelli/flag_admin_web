import 'package:flag_admin_web/domain/models/venue.dart';

abstract class VenueService {
  Future<List<Venue>> list();
  Future<Venue> getById(String id);
}
