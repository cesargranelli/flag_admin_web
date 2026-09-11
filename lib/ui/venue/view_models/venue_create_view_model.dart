import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/venue_repository.dart';

/// ViewModel para a criação de um novo Venue (ADR-011 / MVVM).
class VenueCreateViewModel extends ChangeNotifier {
  final VenueRepository _repository;
  bool _disposed = false;

  VenueCreateViewModel({required VenueRepository repository}) : _repository = repository;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // Form state
  String? _organizationId;
  String? _name;
  String? _address;
  String? _mapsUrl;

  // Getters
  String? get organizationId => _organizationId;
  String? get name => _name;
  String? get address => _address;
  String? get mapsUrl => _mapsUrl;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Inicializa o formulário para criação.
  void init() {
    _organizationId = null;
    _name = null;
    _address = null;
    _mapsUrl = null;
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

  /// Salva o novo venue.
  Future<bool> save() async {
    final organizationId = _organizationId;
    final name = _name;
    final address = _address;
    final mapsUrl = _mapsUrl;

    if (organizationId == null || name == null || name.isEmpty) {
      _errorMessage = 'Preencha todos os campos obrigatórios.';
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
      _errorMessage = 'Não foi possível salvar o campo.';
      return false;
    } finally {
      _isSubmitting = false;
      _safeNotify();
    }
  }
}