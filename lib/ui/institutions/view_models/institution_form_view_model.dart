import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/domain/models/institution.dart';

/// ViewModel da tela de Formulário de Agremiação (ADR-001 / MVVM).
class InstitutionFormViewModel extends ChangeNotifier {
  final InstitutionRepository _repository;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Institution? _savedInstitution;
  Institution? get savedInstitution => _savedInstitution;

  InstitutionFormViewModel({required InstitutionRepository repository})
      : _repository = repository;

  /// Cria ou atualiza a agremiação e sincroniza suas organizações filiadas.
  Future<bool> save({
    String? id,
    required String name,
    required InstitutionType type,
    required List<String> colors,
    required List<String> organizationIds,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'name': name.trim(),
        'type': type.toJson(),
        'colors': colors,
      };

      Institution institution;
      if (id == null) {
        institution = await _repository.createInstitution(body);
      } else {
        institution = await _repository.updateInstitution(id, body);
      }

      await _repository.updateOrganizations(institution.id, organizationIds);

      _savedInstitution = institution;
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
    _savedInstitution = null;
    notifyListeners();
  }
}
