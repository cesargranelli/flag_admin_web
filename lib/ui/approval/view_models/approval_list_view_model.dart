import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/auth_repository.dart';
import 'package:flag_admin_web/src/domain/domain.dart';

/// ViewModel para a listagem de aprovações de usuários (ADR-011 / MVVM).
class ApprovalListViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  ApprovalListViewModel({required AuthRepository repository})
      : _repository = repository;

  List<User> _pendingUsers = const [];
  List<User> get pendingUsers => _pendingUsers;

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
    if (_searchQuery.isEmpty) return _pendingUsers;
    final query = _searchQuery.toLowerCase().trim();
    return _pendingUsers
        .where((u) =>
            u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query))
        .toList(growable: false);
  }

  /// Carrega os usuários pendentes (Stale-While-Revalidate).
  Future<void> load({bool forceRefresh = false, bool silent = false}) async {
    if (_pendingUsers.isEmpty && !silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _isRevalidating = true;
      notifyListeners();
    }

    try {
      final data = await _repository.listPendingUsers();
      _pendingUsers = List<User>.unmodifiable(data);
      _errorMessage = null;
    } catch (e) {
      if (_pendingUsers.isEmpty) {
        _errorMessage = 'Não foi possível carregar as pendências.';
      }
    } finally {
      _isLoading = false;
      _isRevalidating = false;
      notifyListeners();
    }
  }

  /// Aprova um usuário.
  Future<bool> approve(String userId) async {
    try {
      await _repository.approveUser(userId);
      // Invalida cache local
      _pendingUsers = _pendingUsers.where((u) => u.id != userId).toList(growable: false);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rejeita um usuário.
  Future<bool> reject(String userId) async {
    try {
      await _repository.rejectUser(userId);
      _pendingUsers = _pendingUsers.where((u) => u.id != userId).toList(growable: false);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }
}