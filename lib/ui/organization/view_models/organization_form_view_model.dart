import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/src/domain/domain.dart';

/// ViewModel para a tela de Formulário de Organização (ADR-001 / MVVM).
///
/// Encapsula a lógica de negócio de submissão e controle de estado do formulário.
class OrganizationFormViewModel extends ChangeNotifier {
  final OrganizationRepository _repository;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Organization? _createdOrganization;
  Organization? get createdOrganization => _createdOrganization;

  OrganizationFormViewModel({required OrganizationRepository repository})
      : _repository = repository;

  /// Cria a organização chamando a camada de dados.
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
