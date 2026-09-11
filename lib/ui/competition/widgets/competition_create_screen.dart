import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/enums/age_group.dart';
import 'package:flag_admin_web/src/domain/enums/competition_status.dart';
import 'package:flag_admin_web/src/domain/enums/gender.dart';
import 'package:flag_admin_web/src/domain/enums/modality.dart';
import 'package:flag_admin_web/src/domain/enums/tournament_format.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'competition_grouping_section.dart';

/// Tela dedicada EXCLUSIVAMENTE ao CADASTRO de nova competição (ADR-001 / Kickster Design System).
class CompetitionCreateScreen extends ConsumerStatefulWidget {
  const CompetitionCreateScreen({super.key});

  @override
  ConsumerState<CompetitionCreateScreen> createState() =>
      _CompetitionCreateScreenState();
}

class _CompetitionCreateScreenState
    extends ConsumerState<CompetitionCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(competitionCreateViewModelProvider);
    final organizationsAsync = ref.watch(organizationsProvider);

    return AppScreen(
      title: 'Nova Competição',
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem('Competições', route: '/competitions'),
        BreadcrumbItem('Novo'),
      ],
      body: AppLayout.form(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (vm.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Seção 1: Identificação & Organização
                _buildSectionCard(
                  title: 'Identificação & Organização',
                  icon: Icons.emoji_events_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      organizationsAsync.when(
                        loading: () => KicksterDropdown<String>(
                          label: '',
                          hint: 'Carregando organizações...',
                          items: const [],
                          onChanged: null,
                        ),
                        error: (err, stack) => const Text(
                          'Erro ao carregar organizações',
                          style: TextStyle(color: AppColors.danger),
                        ),
                        data: (orgs) => KicksterDropdown<String>(
                          label: '',
                          value: vm.selectedOrganizationId,
                          hint: 'Selecione a Organização Promotora',
                          items: orgs
                              .map(
                                (o) => DropdownMenuItem(
                                  value: o.id,
                                  child: Text(
                                    o.tradeName.isNotEmpty
                                        ? o.tradeName
                                        : o.legalName,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: vm.setOrganization,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Selecione a organização'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      KicksterInput(
                        label: 'Nome da Competição / Torneio',
                        controller: vm.nameController,
                        hintText: 'Ex: Copa Brasil, Campeonato Nacional',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Informe o nome da competição'
                            : null,
                      ),
                      if (vm.displayNamePreview.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Identificação completa: ${vm.displayNamePreview}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: KicksterInput(
                              label: 'Temporada (ex: 2026, 2026.1)',
                              controller: vm.seasonController,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Informe a temporada'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: KicksterDropdown<CompetitionStatus>(
                              label: '',
                              value: vm.status,
                              hint: 'Status Inicial',
                              items: CompetitionStatus.values
                                  .map(
                                    (st) => DropdownMenuItem(
                                      value: st,
                                      child: Text(st.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (st) {
                                if (st != null) vm.setStatus(st);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      KicksterInput(
                        label: 'Descrição e Regulamento Geral (Opcional)',
                        controller: vm.descriptionController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Seção 2: Formato de Disputa
                _buildSectionCard(
                  title: 'Formato de Disputa',
                  icon: Icons.account_tree_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecione o formato de disputa do torneio:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: TournamentFormat.values.map((fmt) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: fmt != TournamentFormat.values.last
                                    ? 12
                                    : 0,
                              ),
                              child: SelectableCard(
                                label: fmt.label,
                                selected: vm.tournamentFormat == fmt,
                                icon: Icons.emoji_events_outlined,
                                minHeight: 90,
                                onTap: () => vm.setTournamentFormat(fmt),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Seção: Estrutura de Agrupamento Dinâmico (Kickster DS)
                CompetitionGroupingSection(vm: vm),

                const SizedBox(height: 16),

                // Seção 3: Modalidade & Categoria
                _buildSectionCard(
                  title: 'Modalidade & Categoria Esportiva',
                  icon: Icons.sports_football_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modalidade de Futebol Americano:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;
                          final cardWidth = isWide
                              ? (constraints.maxWidth - 36) / 4
                              : (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: Modality.values.map((m) {
                              return SizedBox(
                                width: cardWidth,
                                child: SelectableCard(
                                  label: m.label,
                                  selected: vm.selectedModality == m,
                                  icon: Icons.sports_football_outlined,
                                  onTap: () => vm.setModality(m),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Gênero:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: Gender.values.map((g) {
                                    return SelectableChip(
                                      label: g.label,
                                      selected: vm.selectedGender == g,
                                      onTap: () => vm.setGender(g),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Faixa Etária / Categoria:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: AgeGroup.values.map((ag) {
                                    return SelectableChip(
                                      label: ag.label,
                                      selected: vm.selectedAgeGroup == ag,
                                      onTap: () => vm.setAgeGroup(ag),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Seção 4: Datas
                _buildSectionCard(
                  title: 'Datas da Temporada (Opcional)',
                  icon: Icons.date_range_outlined,
                  child: Row(
                    children: [
                      Expanded(
                        child: KicksterInput(
                          label: 'Data de Início',
                          controller: vm.startDateController,
                          hintText: 'AAAA-MM-DD',
                          readOnly: true,
                          onTap: () async {
                            final parsed = DateTime.tryParse(
                              vm.startDateController.text,
                            );
                            final initial = parsed ?? DateTime.now();
                            final picked = await showAppCalendarDialog(
                              context,
                              initialDate: initial,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              vm.startDateController.text =
                                  '${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}';
                            }
                          },
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: KicksterInput(
                          label: 'Data de Término',
                          controller: vm.endDateController,
                          hintText: 'AAAA-MM-DD',
                          readOnly: true,
                          onTap: () async {
                            final startParsed = DateTime.tryParse(
                              vm.startDateController.text,
                            );
                            final parsed = DateTime.tryParse(
                              vm.endDateController.text,
                            );
                            final first = startParsed ?? DateTime(2020);
                            var initial =
                                parsed ?? (startParsed ?? DateTime.now());
                            if (initial.isBefore(first)) initial = first;
                            final picked = await showAppCalendarDialog(
                              context,
                              initialDate: initial,
                              firstDate: first,
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              vm.endDateController.text =
                                  '${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}';
                            }
                          },
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Ações de Rodapé
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    KicksterButton(
                      label: 'Cancelar',
                      variant: KicksterButtonVariant.outline,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    KicksterButton(
                      label: 'Criar Competição',
                      icon: Icons.check,
                      onPressed: vm.isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final result = await vm.create();
                              if (result != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Competição criada com sucesso!',
                                    ),
                                  ),
                                );
                                context.pop();
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(title: title, icon: icon),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.line, width: 1),
          ),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ],
    );
  }
}
