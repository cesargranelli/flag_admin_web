import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/domain/models/institution.dart';

/// ViewModel para a listagem e gestão de Agremiações (ADR-001 / MVVM).
class InstitutionViewModel extends ChangeNotifier {
  final InstitutionRepository _repository;

  InstitutionViewModel({required InstitutionRepository repository})
      : _repository = repository;

  List<Institution> _institutions = const [];
  List<Institution> get institutions => _institutions;

  final Set<String> _selectedIds = <String>{};
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  InstitutionType? _typeFilter;
  InstitutionType? get typeFilter => _typeFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _actionInProgressId;
  String? get actionInProgressId => _actionInProgressId;

  /// Retorna as agremiações aplicando filtros de tipo e busca.
  List<Institution> get filteredInstitutions {
    return _institutions.where((inst) {
      if (_typeFilter != null && inst.type != _typeFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        if (!inst.name.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  /// Carrega as agremiações a partir do repositório.
  Future<void> load({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data =
          await _repository.getInstitutions(forceRefresh: forceRefresh);
      _institutions = List<Institution>.unmodifiable(data);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Exclui uma agremiação.
  Future<bool> delete(String id) async {
    _actionInProgressId = id;
    notifyListeners();

    try {
      await _repository.deleteInstitution(id);
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

  /// Alterna o estado de seleção de uma agremiação.
  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll(Iterable<String> ids) {
    _selectedIds.addAll(ids);
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isNotEmpty) {
      _selectedIds.clear();
      notifyListeners();
    }
  }

  bool isSelected(String id) => _selectedIds.contains(id);

  void setTypeFilter(InstitutionType? type) {
    if (_typeFilter != type) {
      _typeFilter = type;
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
