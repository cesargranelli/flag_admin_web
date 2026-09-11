import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/domain/models/affiliation.dart';
import 'package:flag_admin_web/config/domain_imports.dart';

/// ViewModel da tela de Detalhes de Organização (ADR-001 / MVVM).
class OrganizationDetailViewModel extends ChangeNotifier {
  final OrganizationRepository _repository;
  final String organizationId;

  Organization? _organization;
  Organization? get organization => _organization;

  List<Affiliation> _affiliations = [];
  List<Affiliation> get affiliations => _affiliations;

  List<AffiliationWindow> _windows = [];
  List<AffiliationWindow> get windows => _windows;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingAffiliations = false;
  bool get isLoadingAffiliations => _isLoadingAffiliations;

  bool _isReviewingAffiliation = false;
  bool get isReviewingAffiliation => _isReviewingAffiliation;

  bool _isSavingWindow = false;
  bool get isSavingWindow => _isSavingWindow;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _affiliationsErrorMessage;
  String? get affiliationsErrorMessage => _affiliationsErrorMessage;

  String _selectedSeason = '2026';
  String get selectedSeason => _selectedSeason;

  AffiliationWindow? get currentWindow {
    try {
      return _windows.firstWhere((w) => w.season == _selectedSeason);
    } catch (_) {
      return null;
    }
  }

  OrganizationDetailViewModel({
    required OrganizationRepository repository,
    required this.organizationId,
    Organization? initialOrganization,
  }) : _repository = repository,
       _organization = initialOrganization;

  void setSelectedSeason(String season) {
    if (_selectedSeason != season) {
      _selectedSeason = season;
      notifyListeners();
      loadAffiliations(forceRefresh: true);
    }
  }

  /// Carrega os dados da organização e as solicitações de filiação.
  Future<void> load({bool forceRefresh = false}) async {
    final shouldLoadOrg = _organization == null || forceRefresh;

    if (shouldLoadOrg) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        _organization = await _repository.getOrganization(
          organizationId,
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

    await loadAffiliations(forceRefresh: forceRefresh);
  }

  /// Carrega a lista de pedidos de filiação recebidos por esta organização.
  Future<void> loadAffiliations({bool forceRefresh = true}) async {
    _isLoadingAffiliations = true;
    _affiliationsErrorMessage = null;
    notifyListeners();

    try {
      _affiliations = await _repository.getAffiliations(
        organizationId,
        season: _selectedSeason,
      );
      _affiliationsErrorMessage = null;
    } catch (e) {
      _affiliationsErrorMessage = e.toString();
    } finally {
      _isLoadingAffiliations = false;
      notifyListeners();
    }

    await loadWindows();
  }

  /// Carrega as janelas cadastradas da organização.
  Future<void> loadWindows() async {
    try {
      _windows = await _repository.getAffiliationWindows(organizationId);
      notifyListeners();
    } catch (_) {}
  }

  /// Abre ou atualiza um período de inscrições de filiação.
  Future<bool> openAffiliationWindow({
    required String season,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? instructions,
  }) async {
    _isSavingWindow = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.openAffiliationWindow(organizationId, {
        'season': season,
        'title': title,
        'startDate': startDate.toIso8601String().split('T').first,
        'endDate': endDate.toIso8601String().split('T').first,
        'instructions': instructions,
      });
      await loadWindows();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSavingWindow = false;
      notifyListeners();
    }
  }

  /// Encerra as inscrições da temporada selecionada.
  Future<bool> closeAffiliationWindow(String season) async {
    _isSavingWindow = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.closeAffiliationWindow(organizationId, season);
      await loadWindows();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSavingWindow = false;
      notifyListeners();
    }
  }

  /// Aprova o pedido de filiação de uma agremiação.
  Future<bool> approveAffiliation(String affiliationId) async {
    _isReviewingAffiliation = true;
    _affiliationsErrorMessage = null;
    notifyListeners();

    try {
      await _repository.approveAffiliation(organizationId, affiliationId);
      await loadAffiliations(forceRefresh: true);
      return true;
    } catch (e) {
      _affiliationsErrorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isReviewingAffiliation = false;
      notifyListeners();
    }
  }

  /// Rejeita o pedido de filiação de uma agremiação informando o motivo.
  Future<bool> rejectAffiliation(String affiliationId, String reason) async {
    _isReviewingAffiliation = true;
    _affiliationsErrorMessage = null;
    notifyListeners();

    try {
      await _repository.rejectAffiliation(
        organizationId,
        affiliationId,
        reason,
      );
      await loadAffiliations(forceRefresh: true);
      return true;
    } catch (e) {
      _affiliationsErrorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isReviewingAffiliation = false;
      notifyListeners();
    }
  }
}
