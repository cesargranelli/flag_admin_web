import 'package:flutter/material.dart';
import 'package:flag_admin_web/data/repositories/venue_repository.dart';

/// ViewModel para a criação de um novo Venue (ADR-011 / MVVM).
class VenueCreateViewModel extends ChangeNotifier {
  final VenueRepository _repository;
  bool _disposed = false;

  VenueCreateViewModel({required VenueRepository repository})
      : _repository = repository {
    nameController.addListener(notifyListeners);
    addressController.addListener(notifyListeners);
    mapsUrlController.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _disposed = true;
    nameController.dispose();
    addressController.dispose();
    mapsUrlController.dispose();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // Controllers
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final mapsUrlController = TextEditingController();

  // Form state
  String? _organizationId;

  // Getters
  String? get organizationId => _organizationId;
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Inicializa o formulário para criação.
  void init() {
    _organizationId = null;
    nameController.clear();
    addressController.clear();
    mapsUrlController.clear();
    _safeNotify();
  }

  // Setters
  void setOrganizationId(String? value) {
    _organizationId = value;
    _safeNotify();
  }

  /// Salva o novo venue.
  Future<bool> save() async {
    final organizationId = _organizationId;
    final name = nameController.text;
    final address = addressController.text;
    final mapsUrl = mapsUrlController.text;

    if (organizationId == null || name.isEmpty) {
      _errorMessage = 'Preencha todos os locais obrigatórios.';
      _safeNotify();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await _repository.createVenue(
        organizationId: organizationId,
        name: name,
        address: address,
        mapsUrl: mapsUrl,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Não foi possível salvar o local.';
      return false;
    } finally {
      _isSubmitting = false;
      _safeNotify();
    }
  }
}
