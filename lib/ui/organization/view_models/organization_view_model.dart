import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/src/domain/domain.dart';

/// ViewModel da feature de Organizações (camada ViewModels).
///
/// Responsável por gerenciar o UI State e converter intenções do usuário
/// em comandos para a camada de dados (Repository).
class OrganizationViewModel extends ChangeNotifier {
  final OrganizationRepository _repository;

  OrganizationViewModel({required OrganizationRepository repository})
      : _repository = repository;

  List<Organization> _organizations = const [];
  List<Organization> get organizations => _organizations;

  final Set<String> _selectedIds = <String>{};
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRevalidating = false;
  bool get isRevalidating => _isRevalidating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  OrganizationType? _typeFilter;
  OrganizationType? get typeFilter => _typeFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _showDisabled = false;
  bool get showDisabled => _showDisabled;

  String? _actionInProgressId;
  String? get actionInProgressId => _actionInProgressId;

  /// Retorna as organizações aplicando filtros de busca e tipo.
  List<Organization> get filteredOrganizations {
    return _organizations.where((org) {
      if (_typeFilter != null && org.organizationType != _typeFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final tradeMatch = org.tradeName.toLowerCase().contains(query);
        final legalMatch = org.legalName.toLowerCase().contains(query);
        if (!tradeMatch && !legalMatch) return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Carrega as organizações da camada Repository (Stale-While-Revalidate).
  Future<void> load({bool forceRefresh = false, bool silent = false}) async {
    if (_organizations.isEmpty && !silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _isRevalidating = true;
      notifyListeners();
    }

    try {
      final data = await _repository.getOrganizations(
        forceRefresh: forceRefresh,
        includeDisabled: _showDisabled,
      );
      _organizations = List<Organization>.unmodifiable(data);
      _errorMessage = null;
    } catch (e) {
      if (_organizations.isEmpty) {
        _errorMessage = e.toString();
      }
    } finally {
      _isLoading = false;
      _isRevalidating = false;
      notifyListeners();
    }
  }

  /// Alias explícito conforme ADR-001.
  Future<void> loadOrganizations({bool forceRefresh = false, bool silent = false}) =>
      load(forceRefresh: forceRefresh, silent: silent);

  /// Exclui/desativa uma organização.
  Future<bool> delete(String id) async {
    _actionInProgressId = id;
    notifyListeners();

    try {
      await _repository.deleteOrganization(id);
      _selectedIds.remove(id);
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _actionInProgressId = null;
      notifyListeners();
    }
  }

  /// Alias explícito conforme ADR-001.
  Future<bool> deleteOrganization(String id) => delete(id);

  /// Reativa uma organização previamente desativada.
  Future<bool> reactivate(String id) async {
    _actionInProgressId = id;
    notifyListeners();

    try {
      await _repository.reactivateOrganization(id);
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _actionInProgressId = null;
      notifyListeners();
    }
  }

  /// Alterna o estado de seleção de uma organização.
  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  /// Alias explícito conforme ADR-001.
  void toggleOrganizationSelection(String id) => toggleSelection(id);

  /// Seleciona múltiplos IDs.
  void selectAll(Iterable<String> ids) {
    _selectedIds.addAll(ids);
    notifyListeners();
  }

  /// Limpa a seleção.
  void clearSelection() {
    if (_selectedIds.isNotEmpty) {
      _selectedIds.clear();
      notifyListeners();
    }
  }

  /// Verifica se uma organização específica está selecionada.
  bool isSelected(String id) => _selectedIds.contains(id);

  /// Atualiza o filtro de tipo de organização.
  void setTypeFilter(OrganizationType? type) {
    if (_typeFilter != type) {
      _typeFilter = type;
      notifyListeners();
    }
  }

  /// Atualiza o texto de busca.
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Alterna a exibição de organizações desativadas (admin).
  void setShowDisabled(bool show) {
    if (_showDisabled != show) {
      _showDisabled = show;
      notifyListeners();
      load(forceRefresh: true);
    }
  }
}
