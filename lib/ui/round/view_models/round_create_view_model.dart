import 'package:flag_admin_web/data/repositories/round_repository.dart';
import 'package:flag_admin_web/domain/enums/round_type.dart';
import 'package:flutter/foundation.dart';

/// ViewModel para a criação de uma nova Rodada (ADR-011 / MVVM).
class RoundCreateViewModel extends ChangeNotifier {
  final RoundRepository _repository;

  RoundCreateViewModel({required RoundRepository repository})
    : _repository = repository;

  // Form state
  String? _competitionId;
  int? _number;
  String? _name;
  RoundType? _type;

  // Getters
  String? get competitionId => _competitionId;

  int? get number => _number;

  String? get name => _name;

  RoundType? get type => _type;

  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  /// Inicializa o formulário para criação.
  void init({required String competitionId}) {
    _competitionId = competitionId;
    _number = null;
    _name = null;
    _type = RoundType.regular;
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

  /// Salva a nova rodada.
  Future<bool> save() async {
    final competitionId = _competitionId;
    final number = _number;
    final name = _name;
    final type = _type;

    if (competitionId == null ||
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
      await _repository.createRound(
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
