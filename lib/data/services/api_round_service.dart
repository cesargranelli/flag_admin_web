import 'package:flag_admin_web/data/services/round_service.dart';
import 'package:flag_admin_web/domain/models/round.dart';
import 'package:flag_admin_web/src/api/api_client.dart';
import 'package:flag_admin_web/src/api/services/round_api.dart';

class ApiRoundService implements RoundService {
  final RoundApi _api;

  ApiRoundService(ApiClient client) : _api = RoundApi(client);

  @override
  Future<List<Round>> listByCompetition(String competitionId) =>
      _api.listByCompetition(competitionId);

  @override
  Future<Round> getById(String id) => _api.getById(id);

  @override
  Future<Round> create({
    required String competitionId,
    required int number,
    required String name,
    required RoundType type,
  }) =>
      _api.create(
        competitionId: competitionId,
        number: number,
        name: name,
        type: type,
      );

  @override
  Future<Round> update(
    String id, {
    required String competitionId,
    required int number,
    required String name,
    required RoundType type,
  }) =>
      _api.update(
        id,
        competitionId: competitionId,
        number: number,
        name: name,
        type: type,
      );
}
