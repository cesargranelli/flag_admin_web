import 'package:flag_admin_web/domain/enums/competition_status.dart';
import 'package:flag_admin_web/domain/enums/grouping_type.dart';
import 'package:flag_admin_web/domain/enums/modality.dart';
import 'package:flag_admin_web/config/domain_imports.dart';

import '../api_client.dart';

/// Serviço REST de competições.
class CompetitionApi {
  final ApiClient _client;

  CompetitionApi(this._client);

  /// Lista todas as competições (endpoint público, ordenado por nome).
  /// ADMIN pode passar includeDisabled para receber também os desativados.
  Future<List<Competition>> listAll({bool includeDisabled = false}) =>
      _client.getList(
        '/api/v1/competitions?includeDisabled=$includeDisabled',
        Competition.fromJson,
      );

  Future<List<Competition>> listByOrganization(String organizationId) =>
      _client.getList(
        '/api/v1/organizations/$organizationId/competitions',
        Competition.fromJson,
      );

  Future<Competition> getById(String id) =>
      _client.getOne('/api/v1/competitions/$id', Competition.fromJson);

  /// Exclusão lógica: marca a competição como desativada (DISABLED).
  Future<void> deactivate(String id) =>
      _client.delete('/api/v1/competitions/$id');

  /// Reativa a competição (exclusivo ADMIN), voltando para DRAFT.
  Future<void> reactivate(String id) => _client.post(
    '/api/v1/competitions/$id/reactivate',
    <String, dynamic>{},
    (json) => json,
  );

  Future<Competition> create({
    required String organizationId,
    required String name,
    String? description,
    String? startDate,
    String? endDate,
    CompetitionStatus? status,
    Modality? modality,
    String? gender,
    String? ageGroup,
    GroupingType? groupingType,
    Map<String, dynamic>? groupingConfig,
  }) => _client.post(
    '/api/v1/competitions',
    _body(
      organizationId: organizationId,
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      status: status,
      modality: modality,
      gender: gender,
      ageGroup: ageGroup,
      groupingType: groupingType,
      groupingConfig: groupingConfig,
    ),
    Competition.fromJson,
  );

  Future<Competition> update(
    String id, {
    required String organizationId,
    required String name,
    String? description,
    String? startDate,
    String? endDate,
    CompetitionStatus? status,
    Modality? modality,
    String? gender,
    String? ageGroup,
    GroupingType? groupingType,
    Map<String, dynamic>? groupingConfig,
  }) => _client.put(
    '/api/v1/competitions/$id',
    _body(
      organizationId: organizationId,
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      status: status,
      modality: modality,
      gender: gender,
      ageGroup: ageGroup,
      groupingType: groupingType,
      groupingConfig: groupingConfig,
    ),
    Competition.fromJson,
  );

  Map<String, dynamic> _body({
    required String organizationId,
    required String name,
    String? description,
    String? startDate,
    String? endDate,
    CompetitionStatus? status,
    Modality? modality,
    String? gender,
    String? ageGroup,
    GroupingType? groupingType,
    Map<String, dynamic>? groupingConfig,
  }) => {
    'organizationId': organizationId,
    'name': name,
    if (description != null && description.isNotEmpty)
      'description': description,
    if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
    if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
    if (status != null) 'status': status.toJson(),
    if (modality != null) 'modality': modality.toJson(),
    if (gender != null) 'gender': gender,
    if (ageGroup != null) 'ageGroup': ageGroup,
    if (groupingType != null) 'groupingType': groupingType.toJson(),
    if (groupingConfig != null) 'groupingConfig': groupingConfig,
  };
}
