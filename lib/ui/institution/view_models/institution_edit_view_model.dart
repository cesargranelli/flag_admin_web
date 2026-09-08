import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/domain/models/institution.dart';
import 'package:flag_admin_web/domain/models/organization.dart';

/// ViewModel dedicada exclusivamente à EDIÇÃO de Agremiação existente (ADR-001 / MVVM 1:1).
///
/// Responsabilidade única: carregar a entidade existente pelo ID e salvar as alterações.
class InstitutionEditViewModel extends ChangeNotifier {
  final InstitutionRepository _repository;
  final String institutionId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Institution? _institution;
  Institution? get institution => _institution;

  Institution? _updatedInstitution;
  Institution? get updatedInstitution => _updatedInstitution;

  InstitutionEditViewModel({
    required InstitutionRepository repository,
    required this.institutionId,
    Institution? initialInstitution,
  })  : _repository = repository,
        _institution = initialInstitution;

  /// Carrega os dados da agremiação a ser editada se ainda não foram informados.
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

  /// Salva as alterações da agremiação.
  Future<bool> update({
    required String name,
    String? legalName,
    String? tradeName,
    required InstitutionType type,
    String? abbreviation,
    String? document,
    DocumentType? documentType,
    String? presidentName,
    String? presidentCpf,
    String? email,
    String? phone,
    String? website,
    String? instagram,
    String country = 'BR',
    String? state,
    String? city,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    String? tertiaryColor,
    String? quaternaryColor,
    List<String> colors = const [],
    List<String> organizationIds = const [],
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final finalTradeName = (tradeName != null && tradeName.trim().isNotEmpty)
          ? tradeName.trim()
          : name.trim();
      final finalLegalName = (legalName != null && legalName.trim().isNotEmpty)
          ? legalName.trim()
          : finalTradeName;

      final body = <String, dynamic>{
        'name': finalTradeName,
        'tradeName': finalTradeName,
        'legalName': finalLegalName,
        'type': type.toJson(),
        if (abbreviation != null && abbreviation.trim().isNotEmpty)
          'abbreviation': abbreviation.trim(),
        if (document != null && document.trim().isNotEmpty)
          'document': document.trim(),
        if (documentType != null) 'documentType': documentType.toJson(),
        if (presidentName != null && presidentName.trim().isNotEmpty)
          'presidentName': presidentName.trim(),
        if (presidentCpf != null && presidentCpf.trim().isNotEmpty)
          'presidentCpf': presidentCpf.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (website != null && website.trim().isNotEmpty)
          'website': website.trim(),
        if (instagram != null && instagram.trim().isNotEmpty)
          'instagram': instagram.trim(),
        'country': country.trim().isNotEmpty ? country.trim() : 'BR',
        if (state != null && state.trim().isNotEmpty) 'state': state.trim(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (logoUrl != null && logoUrl.trim().isNotEmpty)
          'logoUrl': logoUrl.trim(),
        if (primaryColor != null && primaryColor.trim().isNotEmpty)
          'primaryColor': primaryColor.trim(),
        if (secondaryColor != null && secondaryColor.trim().isNotEmpty)
          'secondaryColor': secondaryColor.trim(),
        if (tertiaryColor != null && tertiaryColor.trim().isNotEmpty)
          'tertiaryColor': tertiaryColor.trim(),
        if (quaternaryColor != null && quaternaryColor.trim().isNotEmpty)
          'quaternaryColor': quaternaryColor.trim(),
        'colors': colors,
        'organizationIds': organizationIds,
      };

      _updatedInstitution =
          await _repository.updateInstitution(institutionId, body);
      _institution = _updatedInstitution;
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
