import 'package:flag_admin_web/src/api/api_client.dart';
import 'package:flag_admin_web/domain/models/competition.dart';

/// Serviço REST de competições (camada Services - ADR-001).
abstract class CompetitionService {
  factory CompetitionService(ApiClient client) = ApiCompetitionService;

  Future<List<Competition>> getCompetitions({bool includeDisabled = false});
  Future<Competition> getCompetition(String id);
  Future<Competition> createCompetition(Map<String, dynamic> body);
  Future<Competition> updateCompetition(String id, Map<String, dynamic> body);
  Future<void> deactivateCompetition(String id);
  Future<void> reactivateCompetition(String id);
}

/// Implementação padrão consumindo [ApiClient].
class ApiCompetitionService implements CompetitionService {
  final ApiClient _client;

  ApiCompetitionService(this._client);

  @override
  Future<List<Competition>> getCompetitions({bool includeDisabled = false}) =>
      _client.getList(
        '/api/v1/competitions?includeDisabled=',
        Competition.fromJson,
      );

  @override
  Future<Competition> getCompetition(String id) =>
      _client.getOne('/api/v1/competitions/', Competition.fromJson);

  @override
  Future<Competition> createCompetition(Map<String, dynamic> body) =>
      _client.post('/api/v1/competitions', body, Competition.fromJson);

  @override
  Future<Competition> updateCompetition(String id, Map<String, dynamic> body) =>
      _client.put('/api/v1/competitions/', body, Competition.fromJson);

  @override
  Future<void> deactivateCompetition(String id) =>
      _client.delete('/api/v1/competitions/');

  @override
  Future<void> reactivateCompetition(String id) =>
      _client.post('/api/v1/competitions//reactivate', <String, dynamic>{},
          (json) => json);
}
