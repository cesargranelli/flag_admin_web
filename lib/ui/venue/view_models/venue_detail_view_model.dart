import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/venue_repository.dart';
import 'package:flag_admin_web/domain/models/venue.dart';

/// ViewModel para o detalhe de um Venue (ADR-011 / MVVM).
class VenueDetailViewModel extends ChangeNotifier {
  final VenueRepository _repository;

  VenueDetailViewModel({required VenueRepository repository})
      : _repository = repository;

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
    notifyListeners();

    try {
      final venues = await _repository.getVenues(forceRefresh: true);
      _venue = venues.firstWhere(
        (v) => v.id == venueId,
        orElse: () => throw Exception('Campo não encontrado'),
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Não foi possível carregar o campo.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Define o venue diretamente (quando navegado via extra).
  void setVenue(Venue venue) {
    _venue = venue;
    notifyListeners();
  }
}