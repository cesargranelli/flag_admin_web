import 'package:flutter/material.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/enums/grouping_type.dart';
import '../view_models/competition_form_view_model.dart';

/// Seção visual e interativa de Agrupamento de Times (Design System Kickster).
///
/// Permite selecionar entre 3 modelos mutuamente exclusivos:
/// 1. Sem Agrupamento (Tabela Única)
/// 2. Fase de Grupos (com criação/edição/exclusão de grupos)
/// 3. Conferências & Divisões (com conferências customizadas e divisões subordinadas em chips)
class CompetitionGroupingSection extends StatelessWidget {
  final CompetitionFormViewModel vm;

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
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.grid_view_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: group.name,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Nome do Grupo',
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        onChanged: (val) => vm.updateGroupName(index, val.trim()),
                      ),
                    ),
                    if (canRemove)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.danger),
                        tooltip: 'Remover ${group.name}',
                        onPressed: () => vm.removeGroup(index),
                      ),
                  ],
                ),
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
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nome da Conferência e Remoção
                    Row(
                      children: [
                        const Icon(Icons.account_tree_outlined,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            initialValue: conf.name,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Nome da Conferência',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            onChanged: (val) =>
                                vm.updateConferenceName(confIndex, val.trim()),
                          ),
                        ),
                        if (canRemoveConf)
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.danger),
                            tooltip: 'Remover Conferência',
                            onPressed: () => vm.removeConference(confIndex),
                          ),
                      ],
                    ),

                    const Divider(height: 16),

                    // Divisões da Conferência (Chips Interativos)
                    Row(
                      children: [
                        const Text(
                          'Divisões (Opcional):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => vm.addDivision(confIndex),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    size: 14, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  '+ Nova Divisão',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (conf.divisions.isEmpty)
                      const Text(
                        'Sem divisões associadas. Todos os times competirão na conferência diretamente.',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
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
                            padding: const EdgeInsets.only(
                                left: 10, right: 4, top: 2, bottom: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  div.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () =>
                                      vm.removeDivision(confIndex, divIndex),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close,
                                        size: 14,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
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
}
