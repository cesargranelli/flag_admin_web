import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/domain/models/institution.dart';

/// ViewModel da tela de Detalhes de Agremiação (ADR-001 / MVVM).
class InstitutionDetailViewModel extends ChangeNotifier {
  final InstitutionRepository _repository;
  final String institutionId;

  Institution? _institution;
  Institution? get institution => _institution;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  InstitutionDetailViewModel({
    required InstitutionRepository repository,
    required this.institutionId,
    Institution? initialInstitution,
  })  : _repository = repository,
        _institution = initialInstitution;

  /// Carrega os dados da agremiação a partir do repositório.
  Future<void> load({bool forceRefresh = false}) async {
    if (_institution != null && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _institution = await _repository.getInstitution(
        institutionId,
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
}
