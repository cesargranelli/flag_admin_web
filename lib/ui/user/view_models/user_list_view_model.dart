import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/user_repository.dart';
import 'package:flag_admin_web/src/domain/domain.dart';

/// ViewModel para a listagem de Usuários (ADR-011 / MVVM).
class UserListViewModel extends ChangeNotifier {
  final UserRepository _repository;

  UserListViewModel({required UserRepository repository})
      : _repository = repository;

  List<User> _users = const [];
  List<User> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRevalidating = false;
  bool get isRevalidating => _isRevalidating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Retorna os usuários filtrados por busca.
  List<User> get filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final query = _searchQuery.toLowerCase().trim();
    return _users
        .where((u) =>
            u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query))
        .toList(growable: false);
  }

  /// Carrega os usuários (Stale-While-Revalidate).
  Future<void> load({bool forceRefresh = false, bool silent = false}) async {
    if (_users.isEmpty && !silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _isRevalidating = true;
      notifyListeners();
    }

    try {
      final data = await _repository.listUsers();
      _users = List<User>.unmodifiable(data);
      _errorMessage = null;
    } catch (e) {
      if (_users.isEmpty) {
        _errorMessage = 'Não foi possível carregar os usuários.';
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
}