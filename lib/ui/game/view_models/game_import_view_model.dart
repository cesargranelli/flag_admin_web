import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/game_repository.dart';
import 'package:flag_admin_web/src/domain/domain.dart';

/// ViewModel para a importação em lote de Jogos (ADR-011 / MVVM).
class GameImportViewModel extends ChangeNotifier {
  final GameRepository _repository;

  GameImportViewModel({required GameRepository repository})
      : _repository = repository;

  List<GameImportRow>? _rows;
  List<GameImportRow>? get rows => _rows;

  GameBatchResult? _result;
  GameBatchResult? get result => _result;

  bool _isImporting = false;
  bool get isImporting => _isImporting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _roundId;
  String? get roundId => _roundId;

  String? _competitionId;
  String? get competitionId => _competitionId;

  /// Inicializa com contexto da rodada.
  void init({required String roundId, String? competitionId}) {
    _roundId = roundId;
    _competitionId = competitionId;
    notifyListeners();
  }

  /// Parse do CSV e validação.
  bool parseCsv(String content) {
    _errorMessage = null;
    _result = null;

    try {
      final rows = _parseCsv(content);
      if (rows.isEmpty) {
        _errorMessage = 'Nenhuma linha válida encontrada.';
        notifyListeners();
        return false;
      }
      if (rows.length > 500) {
        _errorMessage = 'Máximo de 500 linhas por arquivo.';
        notifyListeners();
        return false;
      }
      _rows = rows;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Arquivo inválido. Verifique o formato.';
      notifyListeners();
      return false;
    }
  }

  /// Define erro manualmente (ex: arquivo não legível).
  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Limpa estado anterior.
  void clear() {
    _rows = null;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Importa os jogos parseados.
  Future<bool> import({
    required List<dynamic> teams,
    required List<dynamic> venues,
  }) async {
    final roundId = _roundId;
    final rows = _rows;
    if (roundId == null || rows == null) return false;

    _isImporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = <Map<String, dynamic>>[];
      for (final row in rows) {
        final homeTeam = teams
            .where((t) =>
                t.name.trim().toLowerCase() == row.home.toLowerCase())
            .toList();
        final awayTeam = teams
            .where((t) =>
                t.name.trim().toLowerCase() == row.away.toLowerCase())
            .toList();
        if (homeTeam.length != 1 || awayTeam.length != 1) continue;

        final scheduledAt = _parseDateTime(row.date, row.time);
        if (scheduledAt == null) continue;

        final venue = row.venue.isEmpty
            ? null
            : venues
                  .where((v) =>
                      v.name.trim().toLowerCase() ==
                      row.venue.toLowerCase())
                  .toList();
        if (row.venue.isNotEmpty && venue!.length != 1) continue;

        items.add({
          'homeTeamId': homeTeam.first.id,
          'awayTeamId': awayTeam.first.id,
          'venueId': row.venue.isNotEmpty ? venue!.first.id : null,
          'scheduledAt': scheduledAt.toIso8601String(),
        });
      }

      final result = await _repository.createBatch(roundId, items);
      _result = result;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Não foi possível importar os jogos.';
      notifyListeners();
      return false;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  List<GameImportRow> _parseCsv(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];
    final delimiter = _detectDelimiter(lines.first);
    final headers = _splitLine(lines.first, delimiter);
    final homeIdx = headers.indexOf('time_casa');
    final awayIdx = headers.indexOf('time_fora');
    final venueIdx = headers.indexOf('campo');
    final dateIdx = headers.indexOf('data');
    final timeIdx = headers.indexOf('hora');

    final rows = <GameImportRow>[];
    for (var i = 1; i < lines.length; i++) {
      final values = _splitLine(lines[i], delimiter);
      if (homeIdx >= 0 &&
          homeIdx < values.length &&
          values[homeIdx].isNotEmpty) {
        final home = values[homeIdx].trim();
        final away = awayIdx >= 0 && awayIdx < values.length
            ? values[awayIdx].trim()
            : '';
        final venue = venueIdx >= 0 && venueIdx < values.length
            ? values[venueIdx].trim()
            : '';
        final date = dateIdx >= 0 && dateIdx < values.length
            ? values[dateIdx].trim()
            : '';
        final time = timeIdx >= 0 && timeIdx < values.length
            ? values[timeIdx].trim()
            : '';
        rows.add(GameImportRow(home, away, venue, date, time));
      }
    }
    return rows;
  }

  String _detectDelimiter(String line) {
    if (line.contains(';')) return ';';
    if (line.contains(',')) return ',';
    return '\t';
  }

  List<String> _splitLine(String line, String delimiter) =>
      line.split(delimiter).map((s) => s.trim()).toList();

  DateTime? _parseDateTime(String date, String time) {
    final d = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(date);
    final t = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(time);
    if (d == null || t == null) return null;
    final day = int.parse(d.group(1)!);
    final month = int.parse(d.group(2)!);
    final year = int.parse(d.group(3)!);
    final hour = int.parse(t.group(1)!);
    final minute = int.parse(t.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return DateTime(year, month, day, hour, minute);
  }
}

class GameImportRow {
  final String home;
  final String away;
  final String venue;
  final String date;
  final String time;

  const GameImportRow(this.home, this.away, this.venue, this.date, this.time);
}
