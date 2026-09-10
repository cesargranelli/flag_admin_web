import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/person_repository.dart';
import 'package:flag_admin_web/domain/models/person.dart';

/// ViewModel da tela de Detalhes de Pessoa (ADR-011 / MVVM).
class PersonDetailViewModel extends ChangeNotifier {
  final PersonRepository _repository;
  final String personId;

  Person? _person;
  Person? get person => _person;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PersonDetailViewModel({
    required PersonRepository repository,
    required this.personId,
    Person? initialPerson,
  })  : _repository = repository,
        _person = initialPerson;

  /// Carrega os dados da pessoa a partir do repositorio.
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
}
