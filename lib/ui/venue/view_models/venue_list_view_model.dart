import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/venue_repository.dart';
import 'package:flag_admin_web/domain/models/venue.dart';

/// ViewModel para a listagem de Venues (ADR-011 / MVVM).
class VenueListViewModel extends ChangeNotifier {
  final VenueRepository _repository;

  VenueListViewModel({required VenueRepository repository})
      : _repository = repository;

  List<Venue> _venues = const [];
  List<Venue> get venues => _venues;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRevalidating = false;
  bool get isRevalidating => _isRevalidating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Retorna os venues filtrados por busca.
  List<Venue> get filteredVenues {
    if (_searchQuery.isEmpty) return _venues;
    final query = _searchQuery.toLowerCase().trim();
    return _venues
        .where((v) => v.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  /// Carrega os venues (Stale-While-Revalidate).
  Future<void> load({bool forceRefresh = false, bool silent = false}) async {
    if (_venues.isEmpty && !silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _isRevalidating = true;
      notifyListeners();
    }

    try {
      final data = await _repository.getVenues(forceRefresh: forceRefresh);
      _venues = List<Venue>.unmodifiable(data);
      _errorMessage = null;
    } catch (e) {
      if (_venues.isEmpty) {
        _errorMessage = 'Não foi possível carregar os campos.';
      }
    } finally {
      _isLoading = false;
      _isRevalidating = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }
}