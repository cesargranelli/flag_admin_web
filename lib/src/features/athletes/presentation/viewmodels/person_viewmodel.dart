import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/providers.dart';

import '../../data/datasources/person_firestore_service.dart';

/// ViewModel para gerenciar estado das pessoas (atletas, técnicos, etc.).
class PersonViewModel extends StateNotifier<AsyncValue<List<Person>>> {
  final PersonFirestoreService _service;

  PersonViewModel(this._service) : super(const AsyncValue.loading()) {
    loadPersons();
  }

  /// Carrega todas as pessoas.
  Future<void> loadPersons() async {
    state = const AsyncValue.loading();
    try {
      final persons = await _service.list();
      state = AsyncValue.data(persons);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Carrega pessoas por role.
  Future<void> loadPersonsByRole(String role) async {
    state = const AsyncValue.loading();
    try {
      final persons = await _service.listByRole(role);
      state = AsyncValue.data(persons);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Cria uma nova pessoa.
  Future<Person?> createPerson({
    required String name,
    String? email,
    String? phone,
    String? gender,
    DateTime? birthDate,
    List<String> roles = const [],
  }) async {
    try {
      final person = Person(
        id: '',
        name: name,
        email: email,
        phone: phone,
        gender: gender,
        birthDate: birthDate,
        roles: roles,
        status: 'ACTIVE',
        createdAt: DateTime.now(),
      );
      final created = await _service.create(person);
      await loadPersons();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza uma pessoa existente.
  Future<void> updatePerson(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(id, data);
      await loadPersons();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove uma pessoa.
  Future<void> deletePerson(String id) async {
    try {
      await _service.delete(id);
      await loadPersons();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider para o ViewModel de pessoas.
final personViewModelProvider =
    StateNotifierProvider<PersonViewModel, AsyncValue<List<Person>>>(
  (ref) {
    final service = ref.watch(personFirestoreServiceProvider);
    return PersonViewModel(service);
  },
);

/// Provider para stream de pessoas.
final personStreamProvider = StreamProvider<List<Person>>((ref) {
  final service = ref.watch(personFirestoreServiceProvider);
  return service.streamList();
});
