import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/roster_repository.dart';
import 'package:flag_admin_web/data/repositories/person_repository.dart';
import 'package:flag_admin_web/domain/models/roster_batch.dart';
import 'package:flag_admin_web/config/domain_imports.dart';

/// ViewModel para a importação em lote de elenco (ADR-011 / MVVM).
class RosterImportViewModel extends ChangeNotifier {
  final RosterRepository _rosterRepository;
  final PersonRepository _personRepository;
  final String teamId;

  RosterImportViewModel({
    required RosterRepository rosterRepository,
    required PersonRepository personRepository,
    required this.teamId,
  }) : _rosterRepository = rosterRepository,
       _personRepository = personRepository;

  List<String>? _personNames;
  List<String>? get personNames => _personNames;

  Map<String, String>? _resolved;
  Map<String, String>? get resolved => _resolved;

  RosterBatchResult? _result;
  RosterBatchResult? get result => _result;

  bool _isImporting = false;
  bool get isImporting => _isImporting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> pickFile() async {
    // File picking is done in the screen, then parseCsv is called
  }

  List<String> _parseCsv(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];
    final delimiter = _detectDelimiter(lines.first);
    final headers = _splitLine(lines.first, delimiter);
    final nameIdx = headers.indexOf('pessoa');

    final names = <String>[];
    for (var i = 1; i < lines.length; i++) {
      final values = _splitLine(lines[i], delimiter);
      if (nameIdx >= 0 &&
          nameIdx < values.length &&
          values[nameIdx].isNotEmpty) {
        names.add(values[nameIdx].trim());
      }
    }
    return names;
  }

  String _detectDelimiter(String line) {
    if (line.contains(';')) return ';';
    if (line.contains(',')) return ',';
    return '\t';
  }

  List<String> _splitLine(String line, String delimiter) =>
      line.split(delimiter).map((s) => s.trim()).toList();

  /// Parse do CSV e validação.
  Future<bool> parseCsv(String content) async {
    _errorMessage = null;
    _result = null;
    _resolved = null;

    try {
      final names = _parseCsv(content);
      if (names.isEmpty) {
        _errorMessage = 'Nenhuma linha válida encontrada.';
        notifyListeners();
        return false;
      }
      if (names.length > 500) {
        _errorMessage = 'Máximo de 500 linhas por arquivo.';
        notifyListeners();
        return false;
      }
      _personNames = names;
      notifyListeners();
      await _resolvePersons(names);
      return true;
    } catch (_) {
      _errorMessage = 'Arquivo inválido. Verifique o formato.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _resolvePersons(List<String> names) async {
    final persons = await _personRepository.getPersons();
    final resolved = <String, String>{};
    for (final name in names) {
      final matches = persons.where((p) => p.name == name).toList();
      if (matches.length == 1) {
        resolved[name] = matches.first.id;
      }
    }
    _resolved = resolved;
    notifyListeners();
  }

  void clear() {
    _personNames = null;
    _resolved = null;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Importa os nomes resolvidos.
  Future<bool> import() async {
    final names = _personNames;
    final resolved = _resolved;
    if (names == null || resolved == null) return false;

    _isImporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = <Map<String, dynamic>>[];
      for (final name in names) {
        final personId = resolved[name];
        if (personId == null) continue;
        items.add({'personId': personId, 'status': 'ativo'});
      }

      final result = await _rosterRepository.createBatch(teamId, items);
      _result = result;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Não foi possível importar o elenco.';
      notifyListeners();
      return false;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }
}
