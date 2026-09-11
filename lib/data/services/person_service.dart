import 'package:flag_admin_web/data/api/api_client.dart';
import 'package:flag_admin_web/domain/models/person.dart';
import 'package:flag_admin_web/domain/models/person_batch.dart';

/// Servico REST de pessoas (camada Services - ADR-001).
abstract class PersonService {
  factory PersonService(ApiClient client) = ApiPersonService;

  Future<List<Person>> getPersons();
  Future<Person> getPerson(String id);
  Future<Person> createPerson(Map<String, dynamic> body);
  Future<Person> updatePerson(String id, Map<String, dynamic> body);
  Future<PersonBatchResult> validateBatch(List<Map<String, dynamic>> items);
  Future<PersonBatchResult> createBatch(List<Map<String, dynamic>> items);
}

/// Implementacao padrao consumindo [ApiClient].
class ApiPersonService implements PersonService {
  final ApiClient _client;

  ApiPersonService(this._client);

  @override
  Future<List<Person>> getPersons() =>
      _client.getList('/api/v1/persons', Person.fromJson);

  @override
  Future<Person> getPerson(String id) =>
      _client.getOne('/api/v1/persons/$id', Person.fromJson);

  @override
  Future<Person> createPerson(Map<String, dynamic> body) async {
    final id = await _client.post<String>(
      '/api/v1/persons',
      body,
      (json) => json['id'] as String,
    );
    return getPerson(id);
  }

  @override
  Future<Person> updatePerson(String id, Map<String, dynamic> body) =>
      _client.put('/api/v1/persons/$id', body, Person.fromJson);

  @override
  Future<PersonBatchResult> validateBatch(List<Map<String, dynamic>> items) =>
      _client.post(
        '/api/v1/persons/batch/dry-run',
        {'athletes': items},
        PersonBatchResult.fromJson,
      );

  @override
  Future<PersonBatchResult> createBatch(List<Map<String, dynamic>> items) =>
      _client.post(
        '/api/v1/persons/batch',
        {'athletes': items},
        PersonBatchResult.fromJson,
      );
}
