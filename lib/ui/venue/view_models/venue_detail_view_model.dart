import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/venue_repository.dart';
import 'package:flag_admin_web/domain/models/venue.dart';

/// ViewModel para o detalhe de um Venue (ADR-011 / MVVM).
class VenueDetailViewModel extends ChangeNotifier {
  final VenueRepository _repository;
  bool _disposed = false;

  VenueDetailViewModel({required VenueRepository repository})
      : _repository = repository;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Venue? _venue;
  Venue? get venue => _venue;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Carrega o venue por ID.
  Future<void> load(String venueId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final venues = await _repository.getVenues(forceRefresh: true);
      _venue = venues.firstWhere(
        (v) => v.id == venueId,
        orElse: () => throw Exception('Local não encontrado'),
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Não foi possível carregar o local.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Define o venue diretamente (quando navegado via extra).
  void setVenue(Venue venue) {
    _venue = venue;
    _safeNotify();
  }
}