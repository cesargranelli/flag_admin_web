import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/venue/view_models/venue_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Gestão de campos de jogo: cards e navegação para o detalhe.
///
/// Listagem em grid de cards (padrão web) com busca por nome; clicar navega
/// para a tela de detalhe do campo.
class VenueListScreen extends ConsumerStatefulWidget {
  const VenueListScreen({super.key});

  @override
  ConsumerState<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends ConsumerState<VenueListScreen> {
  final _searchController = TextEditingController();
  late VenueListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(venueListViewModelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.load(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final organizations = ref.watch(organizationsProvider);

    return AppScreen(
      title: AppStrings.venues,
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.venues),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              KicksterButton(
                label: 'Novo',
                icon: Icons.add,
                onPressed: () => context.go('/venues/new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                if (_viewModel.isLoading) {
                  return const AppLoading(message: 'Carregando campos...');
                }

                if (_viewModel.errorMessage != null) {
                  return AppErrorState(
                    message: _viewModel.errorMessage!,
                    onRetry: () => _viewModel.load(forceRefresh: true),
                  );
                }

                final items = _viewModel.filteredVenues;
                if (items.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.sports_soccer,
                    message: 'Nenhum campo cadastrado',
                    description:
                        'Crie o primeiro campo para começar a usar.',
                    action: KicksterButton(
                      label: 'Criar campo',
                      icon: Icons.add,
                      onPressed: () => context.go('/venues/new'),
                    ),
                  );
                }
                final orgNames = organizations.valueOrNull ??
                    const <Organization>[];
                // Pré-computa o mapa orgId → nome UMA vez (lookup O(1) no card)
                // em vez de percorrer a lista de organizações por card (O(n²)).
                final orgNameById = <String, String>{
                  for (final o in orgNames) o.id: o.tradeName,
                };
                return AppEntityListScreen<Venue>(
                  items: items,
                  cardBuilder: (venue) =>
                      _venueCard(context, venue, orgNameById),
                  searchField: _searchController,
                  countLabel: 'campos',
                  countLabelSingular: 'campo',
                  emptyMessage: 'Nenhum campo encontrado',
                  filter: (all, query) => query.isEmpty
                      ? all
                      : all
                          .where(
                              (v) => v.name.toLowerCase().contains(query))
                          .toList(growable: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Card de campo no padrão Kickster (core #439): ícone de futebol, nome
  /// e subtítulo com organização + endereço.
  Widget _venueCard(
    BuildContext context,
    Venue venue,
    Map<String, String> orgNameById,
  ) {
    // #53: o backend não persiste `organizationId` (default '' no model de
    // domínio, campo só para compatibilidade REST de escrita) — o lookup
    // vazio cai no fallback e o card mostra apenas o endereço.
    final orgName = orgNameById[venue.organizationId] ?? '';
    final subtitle = [
      if (orgName.isNotEmpty) orgName,
      if (venue.address != null && venue.address!.isNotEmpty) venue.address!,
    ].join(' • ');

    return KicksterCard(
      icon: Icons.sports_soccer,
      title: venue.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      onTap: () => context.go('/venues/${venue.id}', extra: venue),
    );
  }
}