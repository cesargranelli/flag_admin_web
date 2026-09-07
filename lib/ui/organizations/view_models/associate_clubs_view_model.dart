import 'package:flutter/foundation.dart';

/// ViewModel para a tela de Associação de Clubes a Competições (ADR-001 / MVVM).
///
/// Gerencia a seleção em lote de clubes e o estado de busca na interface.
class AssociateClubsViewModel extends ChangeNotifier {
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  final Set<String> _selectedOrgIds = <String>{};
  Set<String> get selectedOrgIds => Set.unmodifiable(_selectedOrgIds);

  bool _isSubmittingBatch = false;
  bool get isSubmittingBatch => _isSubmittingBatch;

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void toggleSelection(String orgId) {
    if (_selectedOrgIds.contains(orgId)) {
      _selectedOrgIds.remove(orgId);
    } else {
      _selectedOrgIds.add(orgId);
    }
    notifyListeners();
  }

  void selectAll(Iterable<String> ids) {
    _selectedOrgIds.addAll(ids);
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedOrgIds.isNotEmpty) {
      _selectedOrgIds.clear();
      notifyListeners();
    }
  }

  void setSubmittingBatch(bool submitting) {
    _isSubmittingBatch = submitting;
    notifyListeners();
  }
}
