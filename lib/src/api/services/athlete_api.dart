import 'package:flag_admin_web/src/domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de atletas.
class AthleteApi {
  final ApiClient _client;

  AthleteApi(this._client);

  Future<List<Athlete>> list() =>
      _client.getList('/api/v1/athletes', Athlete.fromJson);

  Future<Athlete> getById(String id) =>
      _client.getOne('/api/v1/athletes/$id', Athlete.fromJson);

  Future<Athlete> create(Map<String, dynamic> body) async {
    final id = await _client.post<String>(
      '/api/v1/athletes',
      body,
      (json) => json['id'] as String,
    );
    return getById(id);
  }

  Future<Athlete> update(String id, Map<String, dynamic> body) =>
      _client.put('/api/v1/athletes/$id', body, Athlete.fromJson);

  /// Exclusão lógica: marca o atleta como desativado (INACTIVE).
  Future<void> deactivate(String id) =>
      _client.delete('/api/v1/athletes/$id');

  /// Reativa o atleta (volta para ACTIVE).
  Future<void> reactivate(String id) =>
      _client.post('/api/v1/athletes/$id/reactivate', <String, dynamic>{},
          (json) => json);

  /// Valida uma carga em lote de atletas sem gravar (dry-run).
  Future<AthleteBatchResult> validateBatch(List<Map<String, dynamic>> athletes) =>
      _client.post(
        '/api/v1/athletes/batch/dry-run',
        {'athletes': athletes},
        AthleteBatchResult.fromJson,
      );

  /// Importa uma carga em lote de atletas.
  Future<AthleteBatchResult> createBatch(List<Map<String, dynamic>> athletes) =>
      _client.post(
        '/api/v1/athletes/batch',
        {'athletes': athletes},
        AthleteBatchResult.fromJson,
      );
}
