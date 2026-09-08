import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/src/domain/domain.dart';

/// ViewModel dedicada exclusivamente à EDIÇÃO de Organização existente (ADR-001 / MVVM 1:1).
///
/// Responsabilidade única: carregar a entidade existente pelo ID e salvar as alterações.
class OrganizationEditViewModel extends ChangeNotifier {
  final OrganizationRepository _repository;
  final String organizationId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Organization? _organization;
  Organization? get organization => _organization;

  Organization? _updatedOrganization;
  Organization? get updatedOrganization => _updatedOrganization;

  OrganizationEditViewModel({
    required OrganizationRepository repository,
    required this.organizationId,
    Organization? initialOrganization,
  })  : _repository = repository,
        _organization = initialOrganization;

  /// Carrega os dados da organização a ser editada caso não tenham sido passados inicialmente.
  Future<void> load({bool forceRefresh = false}) async {
    if (_organization != null && !forceRefresh) return;

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

  /// Salva as alterações da organização existente.
  Future<bool> updateOrganization(Map<String, dynamic> body) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _updatedOrganization =
          await _repository.updateOrganization(organizationId, body);
      _organization = _updatedOrganization;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
