import 'package:flutter/material.dart';
import 'package:flag_admin_web/data/repositories/venue_repository.dart';
import 'package:flag_admin_web/domain/models/venue.dart';

/// ViewModel para a edição de um Venue existente (ADR-011 / MVVM).
class VenueEditViewModel extends ChangeNotifier {
  bool _disposed = false;
  final VenueRepository _repository;

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

  VenueEditViewModel({required VenueRepository repository})
      : _repository = repository;

  // Controllers
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final mapsUrlController = TextEditingController();

  // Form state
  String? _venueId;
  String? _organizationId;

  // Getters
  String? get venueId => _venueId;
  String? get organizationId => _organizationId;
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Inicializa o formulário com dados de um venue existente.
  void init(Venue venue) {
    _venueId = venue.id;
    _organizationId = venue.organizationId;
    nameController.text = venue.name;
    addressController.text = venue.address ?? '';
    mapsUrlController.text = venue.mapsUrl ?? '';
    _safeNotify();
  }

  // Setters
  void setOrganizationId(String? value) {
    _organizationId = value;
    _safeNotify();
  }

  /// Salva as alterações do venue.
  Future<bool> save() async {
    final venueId = _venueId;
    final organizationId = _organizationId;
    final name = nameController.text;
    final address = addressController.text;
    final mapsUrl = mapsUrlController.text;

    if (venueId == null || organizationId == null || name.isEmpty) {
      _errorMessage = 'Preencha todos os campos obrigatórios.';
      _safeNotify();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await _repository.updateVenue(
        venueId,
        organizationId: organizationId,
        name: name,
        address: address,
        mapsUrl: mapsUrl,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Não foi possível salvar o campo.';
      return false;
    } finally {
      _isSubmitting = false;
      _safeNotify();
    }
  }
}
