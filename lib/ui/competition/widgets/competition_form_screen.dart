import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/enums/age_group.dart';
import 'package:flag_admin_web/src/domain/enums/competition_status.dart';
import 'package:flag_admin_web/src/domain/enums/gender.dart';
import 'package:flag_admin_web/src/domain/enums/modality.dart';
import 'package:flag_admin_web/src/domain/enums/tournament_format.dart';
import 'package:flag_admin_web/src/providers/providers.dart';

/// Formulário unificado de Cadastro e Edição de Competição (ADR-001 / Kickster Design System).
class CompetitionFormScreen extends ConsumerStatefulWidget {
  const CompetitionFormScreen({
    super.key,
    this.id,
    this.competition,
  });

  final String? id;
  final Competition? competition;

  @override
  ConsumerState<CompetitionFormScreen> createState() =>
      _CompetitionFormScreenState();
}

class _CompetitionFormScreenState extends ConsumerState<CompetitionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(competitionFormViewModelProvider).init(
            id: widget.id,
            initialData: widget.competition,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(competitionFormViewModelProvider);
    final organizationsAsync = ref.watch(organizationsProvider);
    final isEditing = vm.isEditing;

    return AppScreen(
      title: isEditing ? 'Editar Competição' : 'Nova Competição',
      breadcrumb: [
        const BreadcrumbItem(AppStrings.home, route: '/'),
        const BreadcrumbItem('Competições', route: '/competitions'),
        BreadcrumbItem(isEditing ? 'Editar' : 'Novo'),
      ],
      body: vm.isLoading
          ? const AppLoading(message: 'Carregando dados da competição...')
          : Form(
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
                              label: 'Organização Promotora',
                              hint: 'Carregando organizações...',
                              items: const [],
                              onChanged: null,
                            ),
                            error: (err, stack) => const Text(
                              'Erro ao carregar organizações',
                              style: TextStyle(color: AppColors.danger),
                            ),
                            data: (orgs) => KicksterDropdown<String>(
                              label: 'Organização Promotora',
                              value: vm.selectedOrganizationId,
                              hint: 'Selecione a Organização Promotora',
                              items: orgs
                                  .map((o) => DropdownMenuItem(
                                        value: o.id,
                                        child: Text(o.tradeName.isNotEmpty
                                            ? o.tradeName
                                            : o.legalName),
                                      ))
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
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Informe o nome da competição'
                                : null,
                          ),
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
                                  label: 'Status da Competição',
                                  value: vm.status,
                                  hint: 'Status da Competição',
                                  items: CompetitionStatus.values
                                      .map((st) => DropdownMenuItem(
                                            value: st,
                                            child: Text(st.label),
                                          ))
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

                    // Seção 2: Formato de Disputa & Classificação
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
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: TournamentFormat.values.map((fmt) {
                              final isSelected = vm.tournamentFormat == fmt;
                              return ChoiceChip(
                                label: Text(fmt.label),
                                selected: isSelected,
                                onSelected: (_) => vm.setTournamentFormat(fmt),
                                selectedColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.line,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Seção 3: Modalidade & Categoria
                    _buildSectionCard(
                      title: 'Modalidade & Categoria Esportiva',
                      icon: Icons.sports_football_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Modalidade (Futebol Americano):',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: Modality.values.map((m) {
                              final isSelected = vm.selectedModality == m;
                              return ChoiceChip(
                                label: Text(m.label),
                                selected: isSelected,
                                onSelected: (_) => vm.setModality(m),
                                selectedColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.line,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gênero:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    KicksterDropdown<Gender>(
                                      label: 'Gênero',
                                      value: vm.selectedGender,
                                      hint: 'Gênero',
                                      items: Gender.values
                                          .map((g) => DropdownMenuItem(
                                                value: g,
                                                child: Text(g.label),
                                              ))
                                          .toList(),
                                      onChanged: (g) {
                                        if (g != null) vm.setGender(g);
                                      },
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
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    KicksterDropdown<AgeGroup>(
                                      label: 'Faixa Etária',
                                      value: vm.selectedAgeGroup,
                                      hint: 'Faixa Etária',
                                      items: AgeGroup.values
                                          .map((ag) => DropdownMenuItem(
                                                value: ag,
                                                child: Text(ag.label),
                                              ))
                                          .toList(),
                                      onChanged: (ag) {
                                        if (ag != null) vm.setAgeGroup(ag);
                                      },
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

                    // Seção 4: Período da Competição
                    _buildSectionCard(
                      title: 'Datas da Temporada',
                      icon: Icons.date_range_outlined,
                      child: Row(
                        children: [
                          Expanded(
                            child: KicksterInput(
                              label: 'Data de Início (AAAA-MM-DD)',
                              controller: vm.startDateController,
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: KicksterInput(
                              label: 'Data de Término (AAAA-MM-DD)',
                              controller: vm.endDateController,
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
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
                          label: isEditing ? 'Salvar Alterações' : 'Criar Competição',
                          icon: Icons.check,
                          onPressed: vm.isSaving
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  final result = await vm.save();
                                  if (result != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isEditing
                                            ? 'Competição atualizada com sucesso!'
                                            : 'Competição criada com sucesso!'),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }
}
