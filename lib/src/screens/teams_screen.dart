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
                  cardBuilder: (team) => _teamCard(context, team),
                  searchField: _searchController,
                  countLabel: 'times',
                  countLabelSingular: 'time',
                  emptyMessage: 'Nenhum time encontrado',
                  gridPadding: const EdgeInsets.all(16),
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

  /// Card de time no padrão Kickster: ícone de grupo, nome e subtítulo com
  /// esporte/sigla. Tocar navega para o detalhe do time.
  Widget _teamCard(BuildContext context, Team team) {
    final subtitle = [
      if (team.shortName?.isNotEmpty ?? false) team.shortName!,
      if (team.sportName?.isNotEmpty ?? false) team.sportName!,
    ].join(' · ');

    return KicksterCard(
      icon: Icons.groups_outlined,
      title: team.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      onTap: () => context.push('/teams/${team.id}', extra: team),
    );
  }
}