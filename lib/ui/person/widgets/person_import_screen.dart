import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flag_admin_web/data/api/api.dart';
import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flag_admin_web/domain/models/person_batch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Importacao em lote de pessoas a partir de um arquivo CSV/TXT.
///
/// Fluxo: selecionar arquivo -> validar (dry-run) -> confirmar -> resultado.
class PersonImportScreen extends ConsumerStatefulWidget {
  const PersonImportScreen({super.key});

  @override
  ConsumerState<PersonImportScreen> createState() => _PersonImportScreenState();
}

class _PersonImportScreenState extends ConsumerState<PersonImportScreen> {
  static const _maxLines = 500;

  List<Map<String, dynamic>>? _parsed;
  PersonBatchResult? _validation;
  PersonBatchResult? _result;
  bool _validating = false;
  bool _importing = false;
  String? _errorMessage;

  void _downloadTemplate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modelo CSV'),
        content: const Text(
          'Use o formato abaixo (ponto-e-virgula, UTF-8):\n\n'
          'nome;cpf;funcao;genero;cidade;foto\n'
          'Maria Silva;000.000.000-00;athlete;F;Sao Paulo;https://...\n\n'
          'Colunas: nome (obrigatorio), cpf, funcao (athlete/coach/manager/referee/staff), genero (M/F/O), cidade, foto.',
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
      setState(() => _errorMessage = 'Nao foi possivel ler o arquivo.');
      return;
    }
    final content = utf8.decode(bytes, allowMalformed: true);
    try {
      final parsed = _parseCsv(content);
      if (parsed.isEmpty) {
        setState(() => _errorMessage = 'Nenhuma linha valida encontrada.');
        return;
      }
      if (parsed.length > _maxLines) {
        setState(
          () => _errorMessage = 'Maximo de $_maxLines linhas por arquivo.',
        );
        return;
      }
      setState(() => _parsed = parsed);
    } catch (_) {
      setState(() => _errorMessage = 'Arquivo invalido. Verifique o formato.');
    }
  }

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
      final repo = ref.read(personRepositoryProvider);
      final result = await repo.validateBatch(_toBatchItems(parsed));
      if (mounted) setState(() => _validation = result);
    } on RepositoryException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Nao foi possivel validar o arquivo.');
      }
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  List<Map<String, dynamic>> _toBatchItems(List<Map<String, dynamic>> rows) {
    return rows.map((r) {
      return {
        if (r['nome'] != null) 'name': r['nome'],
        if (r['cpf'] != null) 'cpf': r['cpf'],
        if (r['funcao'] != null) 'role': r['funcao'],
        if (r['genero'] != null) 'gender': r['genero'],
        if (r['cidade'] != null) 'city': r['cidade'],
        if (r['foto'] != null) 'photoUrl': r['foto'],
      };
    }).toList();
  }

  Future<void> _import() async {
    final parsed = _parsed;
    if (parsed == null) return;
    setState(() {
      _importing = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(personRepositoryProvider);
      final result = await repo.createBatch(_toBatchItems(parsed));
      ref.invalidate(personsProvider);
      if (mounted) setState(() => _result = result);
    } on RepositoryException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Nao foi possivel importar as pessoas.');
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
      title: 'Importar pessoas',
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem('Pessoas', route: '/persons'),
        BreadcrumbItem('Importar'),
      ],
      body: AppLayout.form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (result == null) ...[
              Text(
                'Importe varias pessoas de uma vez a partir de um arquivo CSV/TXT.',
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
                  '${_parsed!.length} ${_parsed!.length == 1 ? 'linha' : 'linhas'} lidas. Clique em validar para pre-visualizar.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_validating)
                  const Center(child: CircularProgressIndicator())
                else if (validation == null)
                  KicksterButton(
                    label: 'Validar e pre-visualizar',
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
                      '${validation.valid == 1 ? 'pessoa' : 'pessoas'}',
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
                onPressed: () => context.go('/persons'),
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

  Widget _validationSummary(PersonBatchResult validation) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        KicksterBadge(
          label: '${validation.valid} validos',
          color: AppColors.success,
        ),
        KicksterBadge(
          label: '${validation.invalid} invalidos',
          color: AppColors.danger,
        ),
        KicksterBadge(
          label: '${validation.duplicates} duplicados',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _resultSummary(PersonBatchResult result) {
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

  Widget _validationTable(PersonBatchResult validation) {
    final validLines = validation.lines
        .where((l) => l.status == 'VALID')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pre-visualizacao (linhas validas)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (validLines.isEmpty)
          const Text(
            'Nenhuma linha valida',
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

  Widget _resultTable(PersonBatchResult result) {
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
    'VALID' => 'Valido',
    'INVALID' => 'Invalido',
    'DUPLICATE' => 'Duplicado',
    _ => status,
  };
}
