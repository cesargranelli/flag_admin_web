import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/person/view_models/roster_import_view_model.dart';
import 'package:flag_admin_web/domain/models/roster_batch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Importacao em lote de pessoas para o elenco de um time (CSV/TXT).
class RosterImportScreen extends ConsumerStatefulWidget {
  const RosterImportScreen({super.key, this.teamId});

  final String? teamId;

  @override
  ConsumerState<RosterImportScreen> createState() => _RosterImportScreenState();
}

class _RosterImportScreenState extends ConsumerState<RosterImportScreen> {
  late RosterImportViewModel _vm;

  @override
  void initState() {
    super.initState();
    final teamId = widget.teamId;
    if (teamId != null) {
      _vm = ref.read(rosterImportViewModelProvider(teamId));
    }
  }

  void _showTemplate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modelo CSV'),
        content: const Text(
          'Use o formato abaixo (ponto-e-virgula, UTF-8):\n\n'
          'pessoa;status\n'
          'Maria Silva;ativo\n'
          'Joao Souza;\n\n'
          'Coluna "pessoa" (obrigatoria) e o nome cadastrado. '
          'Coluna "status" (opcional) e ativo ou inativo.',
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      _vm.setError('Não foi possível ler o arquivo.');
      return;
    }
    final content = utf8.decode(bytes, allowMalformed: true);
    final success = await _vm.parseCsv(content);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_vm.errorMessage ?? 'Erro ao processar arquivo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = widget.teamId;

    if (teamId == null || teamId.isEmpty) {
      return AppScreen(
        title: 'Importar elenco',
        breadcrumb: const [
          BreadcrumbItem(AppStrings.home, route: '/'),
          BreadcrumbItem(AppStrings.rosters, route: '/rosters'),
          BreadcrumbItem('Importar'),
        ],
        body: AppLayout.form(
          child: KicksterEmptyState(
            icon: Icons.sports,
            message: 'Time não identificado',
            description:
                'Selecione um time no módulo Elencos para importar pessoas.',
            action: KicksterButton(
              label: 'Ir para Elencos',
              icon: Icons.arrow_back,
              onPressed: () => context.go('/rosters'),
            ),
          ),
        ),
      );
    }

    return AppScreen(
      title: 'Importar elenco',
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.rosters, route: '/rosters'),
        BreadcrumbItem('Importar'),
      ],
      body: AppLayout.form(
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_vm.result == null) ...[
                  Text(
                    'Importe várias pessoas para o elenco a partir de um arquivo CSV/TXT.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  KicksterButton(
                    label: 'Ver modelo CSV',
                    onPressed: _showTemplate,
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
                  if (_vm.personNames != null) ...[
                    Text(
                      '${_vm.personNames!.length} ${_vm.personNames!.length == 1 ? 'pessoa' : 'pessoas'} lidas.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    if (_vm.resolved != null) ...[
                      Text(
                        '${_vm.resolved!.length} ${_vm.resolved!.length == 1 ? 'pessoa' : 'pessoas'} resolvidas.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 16),
                    KicksterButton(
                      label: 'Importar',
                      onPressed: _vm.isImporting ? null : _import,
                      loading: _vm.isImporting,
                    ),
                  ],
                ] else ...[
                  _resultSummary(_vm.result!),
                  const SizedBox(height: 16),
                  _resultTable(_vm.result!),
                  const SizedBox(height: 24),
                  KicksterButton(
                    label: 'Concluir',
                    onPressed: () => context.go('/rosters'),
                    icon: Icons.check,
                  ),
                ],
                if (_vm.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _vm.errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _import() async {
    final success = await _vm.import();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_vm.errorMessage ?? 'Não foi possível importar o elenco.')),
      );
    }
  }

  Widget _resultSummary(RosterBatchResult result) {
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

  Widget _resultTable(RosterBatchResult result) {
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
    'SKIPPED' => 'Ignorado',
    'INVALID' => 'Inválido',
    _ => status,
  };
}