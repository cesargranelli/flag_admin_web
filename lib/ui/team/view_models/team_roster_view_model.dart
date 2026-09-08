import 'package:flag_admin_web/src/api/services/roster_api.dart';
import 'package:flag_admin_web/src/domain/models/athlete.dart';
import 'package:flag_admin_web/src/domain/models/roster_entry.dart';
import 'package:flutter/foundation.dart';

/// ViewModel da tela de Gestao de Elenco (ADR-001 / MVVM).
///
/// Gerencia o elenco-base de um time: listagem de atletas,
/// adicao e remocao de membros.
class TeamRosterViewModel extends ChangeNotifier {
  final RosterApi _rosterApi;
  final String teamId;

  List<RosterEntry> _roster = [];
  List<RosterEntry> get roster => _roster;

  bool _isLoadingRoster = false;
  bool get isLoadingRoster => _isLoadingRoster;

  String? _rosterError;
  String? get rosterError => _rosterError;

  final Set<String> _addingAthleteIds = {};
  Set<String> get addingAthleteIds => Set.unmodifiable(_addingAthleteIds);

  final Set<String> _removingAthleteIds = {};
  Set<String> get removingAthleteIds => Set.unmodifiable(_removingAthleteIds);

  String? _mutationError;
  String? get mutationError => _mutationError;

  TeamRosterViewModel({
    required RosterApi rosterApi,
    required this.teamId,
  }) : _rosterApi = rosterApi;

  /// Carrega (ou recarrega) o elenco-base do time.
  Future<void> loadRoster() async {
    _isLoadingRoster = true;
    _rosterError = null;
    notifyListeners();

    try {
      _roster = await _rosterApi.listByTeam(teamId);
    } catch (e) {
      _rosterError = e.toString();
    } finally {
      _isLoadingRoster = false;
      notifyListeners();
    }
  }

  /// Verifica se um atleta esta no elenco.
  bool isInRoster(String athleteId) =>
      _roster.any((e) => e.athleteId == athleteId);

  /// Retorna a entrada de elenco de um atleta, ou null se nao estiver.
  RosterEntry? entryOf(String athleteId) {
    try {
      return _roster.firstWhere((e) => e.athleteId == athleteId);
    } catch (_) {
      return null;
    }
  }

  /// Adiciona um atleta ao elenco-base do time.
  ///
  /// Retorna `true` em caso de sucesso.
  Future<bool> addAthlete({
    required Athlete athlete,
    String? nickname,
    int? number,
  }) async {
    _addingAthleteIds.add(athlete.id);
    _mutationError = null;
    notifyListeners();

    try {
      await _rosterApi.add(
        teamId: teamId,
        athleteId: athlete.id,
        nickname: nickname,
        number: number,
      );
      await loadRoster();
      return true;
    } catch (e) {
      _mutationError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _addingAthleteIds.remove(athlete.id);
      notifyListeners();
    }
  }

  /// Remove um atleta do elenco-base do time.
  ///
  /// Retorna `true` em caso de sucesso.
  Future<bool> removeAthlete(RosterEntry entry) async {
    _removingAthleteIds.add(entry.athleteId);
    _mutationError = null;
    notifyListeners();

    try {
      await _rosterApi.remove(teamId: teamId, athleteId: entry.athleteId);
      await loadRoster();
      return true;
    } catch (e) {
      _mutationError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _removingAthleteIds.remove(entry.athleteId);
      notifyListeners();
    }
  }
}
