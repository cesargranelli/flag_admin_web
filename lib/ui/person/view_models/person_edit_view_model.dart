import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/person_repository.dart';
import 'package:flag_admin_web/domain/models/person.dart';

/// ViewModel dedicada exclusivamente a EDICAO de Pessoa existente (ADR-011 / MVVM 1:1).
class PersonEditViewModel extends ChangeNotifier {
  final PersonRepository _repository;
  final String personId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Person? _person;
  Person? get person => _person;

  PersonEditViewModel({
    required PersonRepository repository,
    required this.personId,
    Person? initialPerson,
  })  : _repository = repository,
        _person = initialPerson;

  /// Carrega os dados da pessoa a ser editada se ainda nao foram informados.
  Future<void> load({bool forceRefresh = false}) async {
    if (_person != null && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _person = await _repository.getPerson(
        personId,
        forceRefresh: forceRefresh,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Salva as alteracoes da pessoa.
  Future<bool> update({
    required String name,
    String? cpf,
    String? photoUrl,
    String? status,
    DateTime? birthDate,
    String? gender,
    String? city,
    String role = '',
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        if (cpf != null && cpf.trim().isNotEmpty)
          'cpf': cpf.trim().replaceAll(RegExp(r'\D'), ''),
        if (photoUrl != null && photoUrl.trim().isNotEmpty)
          'photoUrl': photoUrl.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        'role': role,
      };

      final updated = await _repository.updatePerson(personId, body);
      _person = updated;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
