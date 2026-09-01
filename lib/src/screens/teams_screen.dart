import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_entity_list_screen.dart';
import '../widgets/app_screen.dart';

/// Módulo Times da home: lista TODOS os times cadastrados na plataforma.
///
/// Este canal é apenas de **visualização**: o cadastro de times acontece no
/// detalhe do clube (`/organizations/:id` → seção "Times" → "Novo time"), e a
/// inscrição em campeonatos na tela dedicada. Por isso não há botão de
/// criar/inscrever aqui.
class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(allTeamsProvider);
    // Nome do clube por id (via organizações) para enriquecer o subtítulo.
    final orgs = ref.watch(organizationsProvider).valueOrNull ?? const [];
    final orgNames = {for (final o in orgs) o.id: o.tradeName};

    return AppScreen(
      title: 'Times',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Times'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: teamsAsync.when(
              loading: () =>
                  const AppLoading(message: 'Carregando times...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar os times',
                onRetry: () => ref.invalidate(allTeamsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.groups_outlined,
                    message: 'Nenhum time cadastrado',
                    description:
                        'Crie o primeiro time no detalhe de um clube.',
                  );
                }
                return AppEntityListScreen<Team>(
                  items: items,
                  cardBuilder: (team) => _teamCard(context, team, orgNames),
                  searchField: _searchController,
                  countLabel: 'times',
                  countLabelSingular: 'time',
                  emptyMessage: 'Nenhum time encontrado',
                  gridPadding: const EdgeInsets.all(16),
                  mainAxisExtent: 104,
                  filter: (all, query) => query.isEmpty
                      ? all
                      : all
                          .where(
                            (t) =>
                                t.name.toLowerCase().contains(query) ||
                                (t.shortName?.toLowerCase().contains(query) ??
                                    false),
                          )
                          .toList(growable: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Card de time no padrão Kickster: logo/avatar, nome (16 w600), subtítulo
  /// com sigla · esporte + clube quando resolvido, e chevron. Tocar navega
  /// para o detalhe do time.
  Widget _teamCard(
    BuildContext context,
    Team team,
    Map<String, String> orgNames,
  ) {
    final subtitleParts = [
      if (team.shortName?.isNotEmpty ?? false) team.shortName!,
      if (team.sportName?.isNotEmpty ?? false) team.sportName!,
    ].join(' · ');
    final orgName = orgNames[team.organizationId];

    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: InkWell(
        onTap: () => context.push('/teams/${team.id}', extra: team),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _teamLogo(context, team),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (orgName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Clube: $orgName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 22,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo do time em quadrado arredondado (raio 12) com fundo `primary` @10%;
  /// fallback para o ícone de grupos quando não há logo.
  Widget _teamLogo(BuildContext context, Team team) {
    final placeholder = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.groups_outlined,
        color: AppColors.primary,
        size: 24,
      ),
    );

    final logo = team.logoUrl;
    if (logo == null || logo.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        logo,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        cacheWidth: (48 * MediaQuery.devicePixelRatioOf(context)).round(),
        cacheHeight: (48 * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}