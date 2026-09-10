import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/person_repository.dart';
import 'package:flag_admin_web/domain/models/person.dart';

/// ViewModel para a listagem e gestao de Pessoas (ADR-011 / MVVM).
class PersonViewModel extends ChangeNotifier {
  final PersonRepository _repository;

  PersonViewModel({required PersonRepository repository})
      : _repository = repository;

  List<Person> _persons = const [];
  List<Person> get persons => _persons;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRevalidating = false;
  bool get isRevalidating => _isRevalidating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _roleFilter;
  String? get roleFilter => _roleFilter;

  /// Retorna as pessoas aplicando filtro de busca e de role.
  List<Person> get filteredPersons {
    var result = _persons;

    if (_roleFilter != null && _roleFilter!.isNotEmpty) {
      result = result
          .where((p) => p.role == _roleFilter)
          .toList(growable: false);
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result
          .where((p) => p.name.toLowerCase().contains(query))
          .toList(growable: false);
    }

    return result;
  }

  /// Carrega as pessoas a partir do repositorio (Stale-While-Revalidate).
  Future<void> load({bool forceRefresh = false, bool silent = false}) async {
    if (_persons.isEmpty && !silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _isRevalidating = true;
      notifyListeners();
    }

    try {
      final data = await _repository.getPersons(forceRefresh: forceRefresh);
      _persons = List<Person>.unmodifiable(data);
      _errorMessage = null;
    } catch (e) {
      if (_persons.isEmpty) {
        _errorMessage = e.toString();
      }
    } finally {
      _isLoading = false;
      _isRevalidating = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void setRoleFilter(String? role) {
    if (_roleFilter != role) {
      _roleFilter = role;
      notifyListeners();
    }
  }
}
