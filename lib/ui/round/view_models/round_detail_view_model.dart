import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/round_repository.dart';
import 'package:flag_admin_web/domain/models/round.dart';

/// ViewModel para o detalhe de uma Rodada (ADR-011 / MVVM).
class RoundDetailViewModel extends ChangeNotifier {
  final RoundRepository _repository;

  RoundDetailViewModel({required RoundRepository repository})
      : _repository = repository;

  Round? _round;
  Round? get round => _round;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Carrega a rodada por ID.
  Future<void> load(String roundId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rounds = await _repository.getRoundsByCompetition(
        _round?.competitionId ?? '',
        forceRefresh: true,
      );
      _round = rounds.firstWhere(
        (r) => r.id == roundId,
        orElse: () => throw Exception('Rodada não encontrada'),
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Não foi possível carregar a rodada.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Define a rodada diretamente (quando navegado via extra).
  void setRound(Round round) {
    _round = round;
    notifyListeners();
  }
}