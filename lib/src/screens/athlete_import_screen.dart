import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flag_admin_web/src/api/flag_api.dart';
import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Importação em lote de atletas a partir de um arquivo CSV/TXT.
///
/// Fluxo: selecionar arquivo -> validar (dry-run) -> confirmar -> resultado.
class AthleteImportScreen extends ConsumerStatefulWidget {
  const AthleteImportScreen({super.key});

  @override
  ConsumerState<AthleteImportScreen> createState() =>
      _AthleteImportScreenState();
}

class _AthleteImportScreenState extends ConsumerState<AthleteImportScreen> {
  static const _maxLines = 500;

  List<Map<String, dynamic>>? _parsed;
  AthleteBatchResult? _validation;
  AthleteBatchResult? _result;
  bool _validating = false;
  bool _importing = false;
  String? _errorMessage;

  void _downloadTemplate() {
    // Mostra o formato num dialog para o usuário copiar.
    showDialog(
      context: context,
      builder: (context) => kicksterModalDialog(
        title: const Text('Modelo CSV'),
        content: const Text(
          'Use o formato abaixo (ponto-e-vírgula, UTF-8):\n\n'
          'nome;apelido;posicao;numero;foto;datanascimento;genero\n'
          'Maria Silva;Ma;WR;10;https://...;01/01/2000;FEMALE\n\n'
          'Colunas: nome (obrigatório), apelido, posicao, numero, foto, '
          'datanascimento (dd/MM/yyyy), genero (MALE/FEMALE/MIXED).',
        ),
        actions: [
          KicksterButton(
            label: 'Fechar',
            variant: KicksterButtonVariant.text,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _parsed = null;
      _validation = null;
      _result = null;
      _errorMessage = null;
    });
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _errorMessage = 'Não foi possível ler o arquivo.');
      return;
    }
    final content = utf8.decode(bytes, allowMalformed: true);
    try {
      final parsed = _parseCsv(content);
      if (parsed.isEmpty) {
        setState(() => _errorMessage = 'Nenhuma linha válida encontrada.');
        return;
      }
      if (parsed.length > _maxLines) {
        setState(
          () => _errorMessage = 'Máximo de $_maxLines linhas por arquivo.',
        );
        return;
      }
      setState(() => _parsed = parsed);
    } catch (_) {
      setState(() => _errorMessage = 'Arquivo inválido. Verifique o formato.');
    }
  }

  /// Faz o parse do CSV, auto-detectando separador (; , ou tab) e cabeçalho.
  List<Map<String, dynamic>> _parseCsv(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];

    final delimiter = _detectDelimiter(lines.first);
    final headers = _splitLineWith(lines.first, delimiter);

    final result = <Map<String, dynamic>>[];
    for (var i = 1; i < lines.length; i++) {
      final values = _splitLineWith(lines[i], delimiter);
      if (values.isEmpty || values.every((v) => v.isEmpty)) continue;
      final map = <String, dynamic>{};
      for (var c = 0; c < headers.length; c++) {
        final value = c < values.length ? values[c].trim() : '';
        if (value.isEmpty) continue;
        map[headers[c]] = value;
      }
      result.add(map);
    }
    return result;
  }

  String _detectDelimiter(String line) {
    if (line.contains(';')) return ';';
    if (line.contains(',')) return ',';
    return '\t';
  }

  List<String> _splitLineWith(String line, String delimiter) {
    return line.split(delimiter).map((s) => s.trim()).toList();
  }

  Future<void> _validate() async {
    final parsed = _parsed;
    if (parsed == null) return;
    setState(() {
      _validating = true;
      _errorMessage = null;
    });
    try {
      final result = await ref
          .read(athleteApiProvider)
          .validateBatch(_toBatchItems(parsed));
      if (mounted) setState(() => _validation = result);
    } on RepositoryException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Não foi possível validar o arquivo.');
      }
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  List<Map<String, dynamic>> _toBatchItems(List<Map<String, dynamic>> rows) {
    return rows.map((r) {
      return {
        if (r['nome'] != null) 'name': r['nome'],
        if (r['apelido'] != null) 'nickname': r['apelido'],
        if (r['posicao'] != null) 'positions': _positionCodes(r['posicao']),
        if (r['numero'] != null && int.tryParse(r['numero']) != null)
          'number': int.parse(r['numero']),
        if (r['foto'] != null) 'photoUrl': r['foto'],
        if (r['datanascimento'] != null)
          'birthDate': _parseBirthDate(r['datanascimento']),
        if (r['genero'] != null) 'gender': r['genero'],
      };
    }).toList();
  }

  /// Converte o campo "posicao" (pode ter várias posições separadas por
  /// `,`/`;`/`/`) em uma lista de códigos, com limite de 3 e sem duplicatas.
  List<String> _positionCodes(String? label) {
    if (label == null || label.trim().isEmpty) return const [];
    final codes = <String>[];
    for (final part in label.split(RegExp(r'[,;/]'))) {
      final code = _positionCode(part.trim());
      if (code != null && !codes.contains(code)) {
        codes.add(code);
        if (codes.length >= 3) break;
      }
    }
    return codes;
  }

  String? _positionCode(String? label) {
    if (label == null || label.isEmpty) return null;
    for (final p in AthletePosition.values) {
      if (p.label.toLowerCase() == label.toLowerCase() ||
          p.name == label.toLowerCase()) {
        return p.toJson();
      }
    }
    return null;
  }

  /// Converte uma data no formato `dd/MM/yyyy` para ISO 8601 (`YYYY-MM-DD`).
  String? _parseBirthDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _import() async {
    final parsed = _parsed;
    if (parsed == null) return;
    setState(() {
      _importing = true;
      _errorMessage = null;
    });
    try {
      final result = await ref
          .read(athleteApiProvider)
          .createBatch(_toBatchItems(parsed));
      ref.invalidate(athletesProvider);
      if (mounted) setState(() => _result = result);
    } on RepositoryException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Não foi possível importar os atletas.');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final validation = _validation;

    return AppScreen(
      title: 'Importar atletas',
      body: AppLayout.form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (result == null) ...[
              Text(
                'Importe vários atletas de uma vez a partir de um arquivo CSV/TXT.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              KicksterButton(
                label: 'Ver modelo CSV',
                onPressed: _downloadTemplate,
                variant: KicksterButtonVariant.outline,
                icon: Icons.download_outlined,
              ),
              const SizedBox(height: 12),
              KicksterButton(
                label: 'Selecionar arquivo',
                onPressed: _pickFile,
                icon: Icons.upload_file,
              ),
              const SizedBox(height: 16),
              if (_parsed != null) ...[
                Text(
                  '${_parsed!.length} ${_parsed!.length == 1 ? 'linha' : 'linhas'} lidas. Clique em validar para pré-visualizar.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_validating)
                  const Center(child: CircularProgressIndicator())
                else if (validation == null)
                  KicksterButton(
                    label: 'Validar e pré-visualizar',
                    onPressed: _validate,
                  ),
              ],
              if (validation != null) ...[
                const SizedBox(height: 12),
                _validationSummary(validation),
                const SizedBox(height: 16),
                _validationTable(validation),
                const SizedBox(height: 16),
                KicksterButton(
                  label:
                      'Importar ${validation.valid} '
                      '${validation.valid == 1 ? 'atleta' : 'atletas'}',
                  onPressed: validation.valid == 0
                      ? null
                      : (_importing ? null : _import),
                  loading: _importing,
                ),
              ],
            ] else ...[
              _resultSummary(result),
              const SizedBox(height: 16),
              _resultTable(result),
              const SizedBox(height: 24),
              KicksterButton(
                label: 'Concluir',
                onPressed: () => context.go('/athletes'),
                icon: Icons.check,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _validationSummary(AthleteBatchResult validation) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        KicksterBadge(
          label: '${validation.valid} válidos',
          color: AppColors.success,
        ),
        KicksterBadge(
          label: '${validation.invalid} inválidos',
          color: AppColors.danger,
        ),
        KicksterBadge(
          label: '${validation.duplicates} duplicados',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _resultSummary(AthleteBatchResult result) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        KicksterBadge(
          label: '${result.imported} importados',
          color: AppColors.success,
        ),
        KicksterBadge(
          label: '${result.skipped} ignorados',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _validationTable(AthleteBatchResult validation) {
    final validLines = validation.lines
        .where((l) => l.status == 'VALID')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pré-visualização (linhas válidas)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (validLines.isEmpty)
          const Text(
            'Nenhuma linha válida',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          for (final line in validLines.take(15))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Linha ${line.line}: ${line.reason ?? ''}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
      ],
    );
  }

  Widget _resultTable(AthleteBatchResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resultado por linha',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final line in result.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Linha ${line.line}: ${_statusLabel(line.status)}'
              '${line.reason != null ? ' — ${line.reason}' : ''}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }

  String _statusLabel(String status) => switch (status) {
    'IMPORTED' => 'Importado',
    'VALID' => 'Válido',
    'INVALID' => 'Inválido',
    'DUPLICATE' => 'Duplicado',
    _ => status,
  };
}
