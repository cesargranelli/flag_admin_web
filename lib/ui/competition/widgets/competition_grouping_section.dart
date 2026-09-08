import 'package:flutter/material.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/enums/grouping_type.dart';
import '../view_models/competition_grouping_state.dart';

/// Seção visual e interativa de Agrupamento de Times (Design System Kickster).
///
/// Permite selecionar entre 3 modelos mutuamente exclusivos:
/// 1. Sem Agrupamento (Tabela Única)
/// 2. Fase de Grupos (com criação/edição/exclusão de grupos)
/// 3. Conferências & Divisões (com conferências customizadas e divisões subordinadas em chips)
class CompetitionGroupingSection extends StatelessWidget {
  final CompetitionGroupingState vm;

  const CompetitionGroupingSection({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(
          title: 'Estrutura de Agrupamento',
          icon: Icons.lan_outlined,
        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Escolha como os times serão organizados na competição:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // 3 Cards Mutuamente Exclusivos em Linha
                Row(
                  children: [
                    Expanded(
                      child: SelectableCard(
                        label: 'Tabela Única',
                        description: 'Classificação unificada',
                        icon: Icons.table_rows_outlined,
                        minHeight: 95,
                        selected: vm.groupingType == GroupingType.none,
                        onTap: () => vm.setGroupingType(GroupingType.none),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableCard(
                        label: 'Fase de Grupos',
                        description: 'Ex: Grupo A, Grupo B',
                        icon: Icons.grid_view_outlined,
                        minHeight: 95,
                        selected: vm.groupingType == GroupingType.groups,
                        onTap: () => vm.setGroupingType(GroupingType.groups),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableCard(
                        label: 'Conferências',
                        description: 'Com ou sem Divisões',
                        icon: Icons.account_tree_outlined,
                        minHeight: 95,
                        selected: vm.groupingType == GroupingType.conferences,
                        onTap: () => vm.setGroupingType(GroupingType.conferences),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Área Contextual de Acordo com a Seleção
                switch (vm.groupingType) {
                  GroupingType.none => _buildNoneState(),
                  GroupingType.groups => _buildGroupsState(context),
                  GroupingType.conferences => _buildConferencesState(context),
                },
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Feedback informativo para modelo sem agrupamento
  Widget _buildNoneState() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Todos os times homologados disputarão uma tabela única. A classificação será consolidada por pontos e critérios de desempate.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gestor de Grupos Dinâmicos
  Widget _buildGroupsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grupos da Competição (${vm.groups.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              KicksterButton(
                label: 'Adicionar Grupo',
                icon: Icons.add,
                variant: KicksterButtonVariant.outline,
                onPressed: vm.addGroup,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...vm.groups.asMap().entries.map((entry) {
            final index = entry.key;
            final group = entry.value;
            final canRemove = vm.groups.length > 2;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: KicksterInput(
                      key: ValueKey('group_${group.id}'),
                      label: 'Grupo ${index + 1}',
                      initialValue: group.name,
                      hintText: 'Ex: Grupo A, Grupo B',
                      prefixIcon: Icons.grid_view_outlined,
                      onChanged: (val) => vm.updateGroupName(index, val.trim()),
                    ),
                  ),
                  if (canRemove) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.danger),
                      tooltip: 'Remover ${group.name}',
                      onPressed: () => vm.removeGroup(index),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            'Mínimo de 2 grupos. Os times serão alocados nestes grupos na homologação.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Gestor de Conferências e Divisões
  Widget _buildConferencesState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conferências (${vm.conferences.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              KicksterButton(
                label: 'Adicionar Conferência',
                icon: Icons.add,
                variant: KicksterButtonVariant.outline,
                onPressed: vm.addConference,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...vm.conferences.asMap().entries.map((entry) {
            final confIndex = entry.key;
            final conf = entry.value;
            final canRemoveConf = vm.conferences.length > 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nome da Conferência no padrão KicksterInput e Remoção
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: KicksterInput(
                            key: ValueKey('conf_${conf.id}'),
                            label: 'Nome da Conferência ${confIndex + 1}',
                            initialValue: conf.name,
                            hintText: 'Ex: Conferência Leste, Americana',
                            prefixIcon: Icons.account_tree_outlined,
                            onChanged: (val) =>
                                vm.updateConferenceName(confIndex, val.trim()),
                          ),
                        ),
                        if (canRemoveConf) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: AppColors.danger),
                            tooltip: 'Remover Conferência',
                            onPressed: () => vm.removeConference(confIndex),
                          ),
                        ],
                      ],
                    ),

                    const Divider(height: 24),

                    // Divisões da Conferência
                    Row(
                      children: [
                        Text(
                          'Divisões (${conf.divisions.length}):',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        KicksterButton(
                          label: 'Nova Divisão',
                          icon: Icons.add,
                          variant: KicksterButtonVariant.text,
                          onPressed: () =>
                              _showAddDivisionDialog(context, confIndex),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (conf.divisions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Text(
                          'Sem divisões associadas. Todos os times competirão diretamente nesta conferência.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: conf.divisions.asMap().entries.map((divEntry) {
                          final divIndex = divEntry.key;
                          final div = divEntry.value;

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.fieldBorder),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _showEditDivisionDialog(
                                context,
                                confIndex,
                                divIndex,
                                div.name,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  right: 6,
                                  top: 6,
                                  bottom: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      div.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => vm.removeDivision(
                                          confIndex, divIndex),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Diálogo no padrão Kickster para adicionar divisão nomeada
  void _showAddDivisionDialog(BuildContext context, int conferenceIndex) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Adicionar Divisão',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informe o nome da divisão que pertencerá a esta conferência:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              KicksterInput(
                label: 'Nome da Divisão',
                controller: controller,
                autofocus: true,
                hintText: 'Ex: Norte, Sul, Cerrado, Capital',
                prefixIcon: Icons.category_outlined,
              ),
            ],
          ),
        ),
        actions: [
          KicksterButton(
            label: 'Cancelar',
            variant: KicksterButtonVariant.text,
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
          KicksterButton(
            label: 'Adicionar',
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                vm.addDivision(conferenceIndex, name);
              }
              Navigator.of(dialogCtx).pop();
            },
          ),
        ],
      ),
    );
  }

  /// Diálogo no padrão Kickster para editar o nome de uma divisão existente
  void _showEditDivisionDialog(
    BuildContext context,
    int conferenceIndex,
    int divisionIndex,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Editar Divisão',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Altere o nome da divisão selecionada:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              KicksterInput(
                label: 'Nome da Divisão',
                controller: controller,
                autofocus: true,
                hintText: 'Ex: Leste, Oeste, Norte, Sul',
                prefixIcon: Icons.category_outlined,
              ),
            ],
          ),
        ),
        actions: [
          KicksterButton(
            label: 'Cancelar',
            variant: KicksterButtonVariant.text,
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
          KicksterButton(
            label: 'Salvar',
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                vm.updateDivisionName(conferenceIndex, divisionIndex, name);
              }
              Navigator.of(dialogCtx).pop();
            },
          ),
        ],
      ),
    );
  }
}
