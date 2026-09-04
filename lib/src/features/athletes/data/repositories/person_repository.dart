import '../datasources/person_firestore_service.dart';

/// Repository para pessoas.
///
/// Abstrai a fonte de dados (Firestore) da lógica de negócio.
class PersonRepository {
  final PersonFirestoreService _datasource;

  PersonRepository(this._datasource);

  /// Lista todas as pessoas.
  Future<List<Person>> getAll() async {
    return await _datasource.list();
  }

  /// Busca pessoa por ID.
  Future<Person?> getById(String id) async {
    return await _datasource.getById(id);
  }

  /// Cria nova pessoa.
  Future<Person> create(Person person) async {
    return await _datasource.create(person);
  }

  /// Atualiza pessoa existente.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _datasource.update(id, data);
  }

  /// Remove pessoa.
  Future<void> delete(String id) async {
    await _datasource.delete(id);
  }

  /// Escuta mudanças em tempo real.
  Stream<List<Person>> watchAll() {
    return _datasource.streamList();
  }

  /// Lista pessoas por role.
  Future<List<Person>> getByRole(String role) async {
    return await _datasource.listByRole(role);
  }
}