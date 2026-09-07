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

  Organization? _savedOrganization;
  Organization? get savedOrganization => _savedOrganization;
  Organization? get createdOrganization => _savedOrganization;

  OrganizationFormViewModel({required OrganizationRepository repository})
      : _repository = repository;

  /// Salva (cria ou atualiza) a organização.
  Future<bool> save({String? id, required Map<String, dynamic> body}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (id != null) {
        _savedOrganization = await _repository.updateOrganization(id, body);
      } else {
        _savedOrganization = await _repository.createOrganization(body);
      }
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

  /// Cria a organização chamando a camada de dados (compatibilidade).
  Future<bool> createOrganization(Map<String, dynamic> body) => save(body: body);

  void reset() {
    _isSubmitting = false;
    _errorMessage = null;
    _savedOrganization = null;
    notifyListeners();
  }
}
