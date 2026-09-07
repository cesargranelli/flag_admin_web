import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/src/domain/domain.dart';

/// ViewModel da tela de Detalhes de Organização (ADR-001 / MVVM).
class OrganizationDetailViewModel extends ChangeNotifier {
  final OrganizationRepository _repository;
  final String organizationId;

  Organization? _organization;
  Organization? get organization => _organization;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  OrganizationDetailViewModel({
    required OrganizationRepository repository,
    required this.organizationId,
    Organization? initialOrganization,
  })  : _repository = repository,
        _organization = initialOrganization;

  /// Carrega os dados da organização por ID a partir do repositório.
  Future<void> load({bool forceRefresh = false}) async {
    if (_organization != null && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _organization = await _repository.getOrganization(organizationId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
