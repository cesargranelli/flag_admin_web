import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/roster_repository.dart';
import 'package:flag_admin_web/data/repositories/person_repository.dart';
import 'package:flag_admin_web/domain/models/person.dart';
import 'package:flag_admin_web/domain/models/roster_entry.dart';

/// ViewModel da tela de Gestao de Elenco (ADR-011 / MVVM).
///
/// Utiliza [PersonRepository] (novo pacote person) em vez de ParticipantRepository.
class RosterViewModel extends ChangeNotifier {
  final RosterRepository _rosterRepository;
  final PersonRepository _personRepository;
  final String teamId;

  List<RosterEntry> _roster = [];
  List<RosterEntry> get roster => _roster;

  List<Person> _persons = [];
  List<Person> get persons => _persons;

  bool _isLoadingRoster = false;
  bool get isLoadingRoster => _isLoadingRoster;

  bool _isLoadingPersons = false;
  bool get isLoadingPersons => _isLoadingPersons;

  String? _rosterError;
  String? get rosterError => _rosterError;

  String? _personsError;
  String? get personsError => _personsError;

  final Set<String> _addingAthleteIds = {};
  Set<String> get addingAthleteIds => Set.unmodifiable(_addingAthleteIds);

  final Set<String> _removingAthleteIds = {};
  Set<String> get removingAthleteIds => Set.unmodifiable(_removingAthleteIds);

  String? _mutationError;
  String? get mutationError => _mutationError;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  RosterViewModel({
    required RosterRepository rosterRepository,
    required PersonRepository personRepository,
    required this.teamId,
  })  : _rosterRepository = rosterRepository,
        _personRepository = personRepository;

  /// Retorna as pessoas filtrados por busca.
  List<Person> get filteredPersons {
    if (_searchQuery.isEmpty) return _persons;
    final query = _searchQuery.toLowerCase().trim();
    return _persons
        .where((p) => p.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  /// Verifica se uma pessoa esta no elenco.
  bool isInRoster(String athleteId) =>
      _roster.any((e) => e.athleteId == athleteId);

  /// Retorna a entrada de elenco de uma pessoa, ou null se nao estiver.
  RosterEntry? entryOf(String athleteId) {
    try {
      return _roster.firstWhere((e) => e.athleteId == athleteId);
    } catch (_) {
      return null;
    }
  }

  /// Carrega o elenco e as pessoas da plataforma.
  Future<void> load({bool forceRefresh = false}) async {
    _isLoadingRoster = true;
    _rosterError = null;
    _isLoadingPersons = true;
    _personsError = null;
    notifyListeners();

    try {
      _roster = await _rosterRepository.getRoster(teamId, forceRefresh: forceRefresh);
    } catch (e) {
      _rosterError = e.toString();
    } finally {
      _isLoadingRoster = false;
      notifyListeners();
    }

    try {
      _persons = await _personRepository.getPersons(forceRefresh: forceRefresh);
    } catch (e) {
      _personsError = e.toString();
    } finally {
      _isLoadingPersons = false;
      notifyListeners();
    }
  }

  /// Adiciona uma pessoa ao elenco.
  Future<bool> addPerson({
    required Person person,
    String? nickname,
    int? number,
  }) async {
    _addingAthleteIds.add(person.id);
    _mutationError = null;
    notifyListeners();

    try {
      await _rosterRepository.addAthlete(
        teamId: teamId,
        athleteId: person.id,
        nickname: nickname,
        number: number,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _mutationError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _addingAthleteIds.remove(person.id);
      notifyListeners();
    }
  }

  /// Remove uma pessoa do elenco.
  Future<bool> removePerson(RosterEntry entry) async {
    _removingAthleteIds.add(entry.athleteId);
    _mutationError = null;
    notifyListeners();

    try {
      await _rosterRepository.removeAthlete(
        teamId: teamId,
        athleteId: entry.athleteId,
      );
      await load(forceRefresh: true);
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

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }
}
