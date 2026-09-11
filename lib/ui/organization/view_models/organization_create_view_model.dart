import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/config/domain_imports.dart';

/// ViewModel dedicada exclusivamente ao CADASTRO de nova Organização (ADR-001 / MVVM 1:1).
///
/// Responsabilidade única: cadastrar uma nova entidade (sem ID, sem busca inicial).
class OrganizationCreateViewModel extends ChangeNotifier {
  final OrganizationRepository _repository;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Organization? _createdOrganization;
  Organization? get createdOrganization => _createdOrganization;

  OrganizationCreateViewModel({required OrganizationRepository repository})
    : _repository = repository;

  /// Cria uma nova organização.
  Future<bool> createOrganization(Map<String, dynamic> body) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _createdOrganization = await _repository.createOrganization(body);
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

  void reset() {
    _isSubmitting = false;
    _errorMessage = null;
    _createdOrganization = null;
    notifyListeners();
  }
}
