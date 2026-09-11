import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/venue_repository.dart';
import 'package:flag_admin_web/domain/models/venue.dart';

/// ViewModel para a edição de um Venue existente (ADR-011 / MVVM).
class VenueEditViewModel extends ChangeNotifier {
  bool _disposed = false;
  final VenueRepository _repository;

  @override
  void dispose() { _disposed = true; super.dispose(); }

  void _safeNotify() { if (!_disposed) notifyListeners(); }

  VenueEditViewModel({required VenueRepository repository})
      : _repository = repository;

  // Form state
  String? _venueId;
  String? _organizationId;
  String? _name;
  String? _address;
  String? _mapsUrl;

  // Getters
  String? get venueId => _venueId;
  String? get organizationId => _organizationId;
  String? get name => _name;
  String? get address => _address;
  String? get mapsUrl => _mapsUrl;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Inicializa o formulário com dados de um venue existente.
  void init(Venue venue) {
    _venueId = venue.id;
    _organizationId = venue.organizationId;
    _name = venue.name;
    _address = venue.address;
    _mapsUrl = venue.mapsUrl;
    _safeNotify();
  }

  // Setters
  void setOrganizationId(String? value) {
    _organizationId = value;
    _safeNotify();
  }

  void setName(String? value) {
    _name = value;
    _safeNotify();
  }

  void setAddress(String? value) {
    _address = value;
    _safeNotify();
  }

  void setMapsUrl(String? value) {
    _mapsUrl = value;
    _safeNotify();
  }

  /// Salva as alterações do venue.
  Future<bool> save() async {
    final venueId = _venueId;
    final organizationId = _organizationId;
    final name = _name;
    final address = _address;
    final mapsUrl = _mapsUrl;

    if (venueId == null || organizationId == null || name == null || name.isEmpty) {
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