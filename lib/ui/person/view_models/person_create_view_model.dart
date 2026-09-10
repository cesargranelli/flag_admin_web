import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/person_repository.dart';
import 'package:flag_admin_web/domain/models/person.dart';

/// ViewModel dedicada exclusivamente ao CADASTRO de nova Pessoa (ADR-011 / MVVM 1:1).
class PersonCreateViewModel extends ChangeNotifier {
  final PersonRepository _repository;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Person? _createdPerson;
  Person? get createdPerson => _createdPerson;

  PersonCreateViewModel({required PersonRepository repository})
      : _repository = repository;

  /// Cria a pessoa com dados cadastrais completos.
  Future<bool> create({
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

      _createdPerson = await _repository.createPerson(body);
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

  void reset() {
    _isSubmitting = false;
    _errorMessage = null;
    _createdPerson = null;
    notifyListeners();
  }
}
