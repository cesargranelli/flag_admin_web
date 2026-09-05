import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/domain/competition_permissions.dart';
import '../../../../providers/providers.dart';

/// Gestão de rodadas: lista por competição e acesso ao detalhe.
///
/// O fluxo agora é: competição → rodadas.
/// As categories foram removidas; as rodadas associam-se diretamente
/// ao competition_id (migração V24).
class RoundsScreen extends ConsumerStatefulWidget {
  const RoundsScreen({super.key});

  @override
  ConsumerState<RoundsScreen> createState() => _RoundsScreenState();
}

class _RoundsScreenState extends ConsumerState<RoundsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);

    final compItems = competitions.valueOrNull ?? const [];
    // P4 #461: competição efetiva = selecionada ?? primeira da lista.
    final effectiveComp = ref.watch(effectiveCompetitionProvider);

    // Issue #261: criação/edição de rodadas exige ser criador da
    // competição ou ADMIN (o backend já bloqueia as escritas).
    // Issue #305: e apenas com a competição em DRAFT — publicado/encerrado
    // tem a estrutura travada (somente leitura).
    final selectedCompetitionObj = compItems
        .where((c) => c.id == effectiveComp)
        .firstOrNull;
    final isDraft =
        selectedCompetitionObj?.status == CompetitionStatus.draft;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider.select((a) => a.state.user)),
      selectedCompetitionObj,
    );
    final canManage = canEdit && isDraft;

    return AppScreen(
      title: 'Rodadas',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.rounds, route: '/rounds'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              if (effectiveComp != null && canManage)
                KicksterButton(
                  label: 'Novo',
                  icon: Icons.add,
                  onPressed: () =>
                      context.go('/rounds/new', extra: effectiveComp),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: competitions.when(
              loading: () =>
                  const AppLoading(message: 'Carregando competições...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar as competições',
                onRetry: () => ref.invalidate(competitionsProvider),
              ),
              data: (_) {
                if (compItems.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.emoji_events_outlined,
                    message: 'Nenhuma competição cadastrada',
                    description:
                        'Crie uma competição para adicionar rodadas.',
                    action: KicksterButton(
                      label: 'Criar competição',
                      icon: Icons.add,
                      onPressed: () => context.go('/competitions/new'),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KicksterDropdown<String>(
                          key: ValueKey('comp-$effectiveComp'),
                          label: 'Competição',
                          value: effectiveComp,
                          items: compItems
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            ref
                                .read(selectedCompetitionProvider.notifier)
                                .state = value;
                            ref.read(selectedRoundProvider.notifier).state =
                                null;
                          },
                        ),
                        if (!canManage)
                          EditRestrictionNote(
                            message: !isDraft
                                ? 'Competição publicada — as rodadas estão '
                                    'travadas.'
                                : 'Apenas o criador da competição pode '
                                    'gerenciar rodadas.',
                          ),
                      ],
                    ),
                    // Grid em altura finita (Expanded) → virtualização real.
                    const SizedBox(height: 16),
                    Expanded(
                      child: effectiveComp != null
                          ? ref
                                .watch(roundsProvider(effectiveComp))
                                .when(
                                  loading: () => const AppLoading(
                                    message: 'Carregando rodadas...',
                                  ),
                                  error: (error, stackTrace) =>
                                      AppErrorState(
                                    message:
                                        'Não foi possível carregar as rodadas',
                                    onRetry: () => ref.invalidate(
                                        roundsProvider(effectiveComp)),
                                  ),
                                  data: (items) {
                                    if (items.isEmpty) {
                                      return KicksterEmptyState(
                                        icon: Icons.format_list_numbered,
                                        message:
                                            'Nenhuma rodada cadastrada',
                                        description:
                                            'Crie a primeira rodada da competição.',
                                        action: KicksterButton(
                                          label: 'Criar rodada',
                                          icon: Icons.add,
                                          onPressed: () => context.go(
                                            '/rounds/new',
                                            extra: effectiveComp,
                                          ),
                                        ),
                                      );
                                    }
                                    return AppEntityListScreen<Round>(
                                      items: items,
                                      cardBuilder: (round) =>
                                          _roundCard(context, round),
                                      searchField: _searchController,
                                      countLabel: 'rodadas',
                                      countLabelSingular: 'rodada',
                                      emptyMessage:
                                          'Nenhuma rodada encontrada',
                                      gridPadding:
                                          const EdgeInsets.all(16),
                                      filter: (all, query) => query.isEmpty
                                          ? all
                                          : all
                                              .where(
                                                (r) => r.name
                                                    .toLowerCase()
                                                    .contains(query),
                                              )
                                              .toList(growable: false),
                                    );
                                  },
                                )
                          : KicksterEmptyState(
                              icon: Icons.format_list_numbered,
                              message: 'Nenhuma rodada cadastrada',
                              description:
                                  'Crie uma competição para adicionar rodadas.',
                              action: KicksterButton(
                                label: 'Criar competição',
                                icon: Icons.add,
                                onPressed: () =>
                                    context.go('/competitions/new'),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundCard(BuildContext context, Round round) {
    return KicksterCard(
      icon: Icons.format_list_numbered,
      title: round.name,
      subtitle: 'Rodada ${round.number} · ${round.type.label}',
      trailing: const Icon(
        Icons.chevron_right,
        size: 22,
        color: AppColors.textSecondary,
      ),
      onTap: () => context.push('/rounds/${round.id}', extra: round),
    );
  }
}
