import 'package:flag_admin_web/data/repositories/round_repository.dart';
import 'package:flag_admin_web/domain/enums/round_type.dart';
import 'package:flag_admin_web/domain/models/round.dart';
import 'package:flutter/foundation.dart';

/// ViewModel para a edição de uma Rodada existente (ADR-011 / MVVM).
class RoundEditViewModel extends ChangeNotifier {
  final RoundRepository _repository;

  RoundEditViewModel({required RoundRepository repository})
    : _repository = repository;

  // Form state
  String? _competitionId;
  int? _number;
  String? _name;
  RoundType? _type;
  String? _roundId;

  // Getters
  String? get competitionId => _competitionId;

  int? get number => _number;

  String? get name => _name;

  RoundType? get type => _type;

  String? get roundId => _roundId;

  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  /// Inicializa o formulário com dados de uma rodada existente.
  void init(Round round) {
    _roundId = round.id;
    _competitionId = round.competitionId;
    _number = round.number;
    _name = round.name;
    _type = round.type;
    notifyListeners();
  }

  // Setters
  void setNumber(int? value) {
    _number = value;
    notifyListeners();
  }

  void setName(String? value) {
    _name = value;
    notifyListeners();
  }

  void setType(RoundType? value) {
    _type = value;
    notifyListeners();
  }

  /// Salva as alterações da rodada.
  Future<bool> save() async {
    final competitionId = _competitionId;
    final roundId = _roundId;
    final number = _number;
    final name = _name;
    final type = _type;

    if (competitionId == null ||
        roundId == null ||
        number == null ||
        name == null ||
        type == null) {
      _errorMessage = 'Preencha todos os campos obrigatórios.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateRound(
        roundId,
        competitionId: competitionId,
        number: number,
        name: name,
        type: type,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Não foi possível salvar a rodada.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
