import 'package:flag_admin_web/src/api/api_client.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/domain/models/enrollment_window.dart';

/// Serviço REST de competições (camada Services - ADR-001).
abstract class CompetitionService {
  factory CompetitionService(ApiClient client) = ApiCompetitionService;

  Future<List<Competition>> getCompetitions({bool includeDisabled = false});
  Future<Competition> getCompetition(String id);
  Future<Competition> createCompetition(Map<String, dynamic> body);
  Future<Competition> updateCompetition(String id, Map<String, dynamic> body);
  Future<void> deactivateCompetition(String id);
  Future<void> reactivateCompetition(String id);
  Future<EnrollmentWindow> getEnrollmentWindow(String competitionId);
  Future<List<EnrollmentWindow>> getOpenEnrollmentWindows();
  Future<EnrollmentWindow> openEnrollmentWindow(String competitionId, Map<String, dynamic> body);
  Future<EnrollmentWindow> closeEnrollmentWindow(String competitionId);
}

/// Implementação padrão consumindo [ApiClient].
class ApiCompetitionService implements CompetitionService {
  final ApiClient _client;

  ApiCompetitionService(this._client);

  @override
  Future<List<Competition>> getCompetitions({bool includeDisabled = false}) =>
      _client.getList(
        '/api/v1/competitions?includeDisabled=$includeDisabled',
        Competition.fromJson,
      );

  @override
  Future<Competition> getCompetition(String id) =>
      _client.getOne('/api/v1/competitions/$id', Competition.fromJson);

  @override
  Future<Competition> createCompetition(Map<String, dynamic> body) =>
      _client.post('/api/v1/competitions', body, Competition.fromJson);

  @override
  Future<Competition> updateCompetition(String id, Map<String, dynamic> body) =>
      _client.put('/api/v1/competitions/$id', body, Competition.fromJson);

  @override
  Future<void> deactivateCompetition(String id) =>
      _client.delete('/api/v1/competitions/$id');

  @override
  Future<void> reactivateCompetition(String id) =>
      _client.post('/api/v1/competitions/$id/reactivate', <String, dynamic>{},
          (json) => json);

  @override
  Future<EnrollmentWindow> getEnrollmentWindow(String competitionId) =>
      _client.getOne(
        '/api/v1/competitions/$competitionId/enrollment-windows',
        EnrollmentWindow.fromJson,
      );

  @override
  Future<List<EnrollmentWindow>> getOpenEnrollmentWindows() =>
      _client.getList(
        '/api/v1/enrollment-windows/open',
        EnrollmentWindow.fromJson,
      );

  @override
  Future<EnrollmentWindow> openEnrollmentWindow(
    String competitionId,
    Map<String, dynamic> body,
  ) =>
      _client.post(
        '/api/v1/competitions/$competitionId/enrollment-windows',
        body,
        EnrollmentWindow.fromJson,
      );

  @override
  Future<EnrollmentWindow> closeEnrollmentWindow(String competitionId) =>
      _client.post(
        '/api/v1/competitions/$competitionId/enrollment-windows/close',
        <String, dynamic>{},
        EnrollmentWindow.fromJson,
      );
}
