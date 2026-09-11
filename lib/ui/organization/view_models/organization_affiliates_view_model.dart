import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/domain/models/affiliation.dart';
import 'package:flag_admin_web/config/domain_imports.dart';

/// ViewModel da tela de Consulta de Agremiações Filiadas (ADR-001 / MVVM 1:1).
class OrganizationAffiliatesViewModel extends ChangeNotifier {
  final OrganizationRepository _repository;
  final String organizationId;

  Organization? _organization;
  Organization? get organization => _organization;

  List<Affiliation> _affiliations = [];
  List<Affiliation> get affiliations => _affiliations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isReviewing = false;
  bool get isReviewing => _isReviewing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Filtros
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedSeason = '2026';
  String get selectedSeason => _selectedSeason;

  String? _selectedStatus; // null = Todos, 'APPROVED', 'PENDING', 'REJECTED'
  String? get selectedStatus => _selectedStatus;

  String? _selectedType; // null = Todos, 'CLUB', 'UNIVERSITY'
  String? get selectedType => _selectedType;

  OrganizationAffiliatesViewModel({
    required OrganizationRepository repository,
    required this.organizationId,
    Organization? initialOrganization,
  }) : _repository = repository,
       _organization = initialOrganization;

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void setSelectedSeason(String season) {
    if (_selectedSeason != season) {
      _selectedSeason = season;
      notifyListeners();
      load(forceRefresh: true);
    }
  }

  void setSelectedStatus(String? status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      notifyListeners();
    }
  }

  void setSelectedType(String? type) {
    if (_selectedType != type) {
      _selectedType = type;
      notifyListeners();
    }
  }

  /// Lista filtrada em memória com base nos critérios selecionados.
  List<Affiliation> get filteredAffiliations {
    return _affiliations.where((a) {
      // Filtro de busca textual (nome da instituição ou responsável)
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final nameMatches = a.institutionName.toLowerCase().contains(q);
        final respMatches = a.requestedBy?.toLowerCase().contains(q) ?? false;
        if (!nameMatches && !respMatches) return false;
      }

      // Filtro de status
      if (_selectedStatus != null && _selectedStatus != 'ALL') {
        if (a.status != _selectedStatus) return false;
      }

      // Filtro de tipo (CLUB / UNIVERSITY)
      if (_selectedType != null && _selectedType != 'ALL') {
        if (a.institutionType != _selectedType) return false;
      }

      return true;
    }).toList();
  }

  int get approvedCount => _affiliations.where((a) => a.isApproved).length;
  int get pendingCount => _affiliations.where((a) => a.isPending).length;

  /// Carrega a organização e suas filiações.
  Future<void> load({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_organization == null || forceRefresh) {
        _organization = await _repository.getOrganization(
          organizationId,
          forceRefresh: forceRefresh,
        );
      }
      _affiliations = await _repository.getAffiliations(
        organizationId,
        season: _selectedSeason,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aprova a filiação de um clube.
  Future<bool> approveAffiliation(String affiliationId) async {
    _isReviewing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.approveAffiliation(organizationId, affiliationId);
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isReviewing = false;
      notifyListeners();
    }
  }

  /// Rejeita a filiação de um clube com justificativa.
  Future<bool> rejectAffiliation(String affiliationId, String reason) async {
    _isReviewing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.rejectAffiliation(
        organizationId,
        affiliationId,
        reason,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isReviewing = false;
      notifyListeners();
    }
  }
}
