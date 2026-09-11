import 'dart:async';

import 'package:flag_admin_web/domain/models/organization.dart';
import 'package:flag_admin_web/domain/models/venue.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/venue/view_models/venue_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VenueListScreen extends ConsumerStatefulWidget {
  const VenueListScreen({super.key});

  @override
  ConsumerState<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends ConsumerState<VenueListScreen> with WidgetsBindingObserver {
  late final TextEditingController _searchController;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(venueListViewModelProvider).load(forceRefresh: true);
    });
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _revalidateIfActive(silent: true);
    });
  }

  void _revalidateIfActive({bool silent = true}) {
    if (!mounted) return;
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == '/venues') {
      ref.read(venueListViewModelProvider).load(forceRefresh: true, silent: silent);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _revalidateIfActive(silent: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == '/venues') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revalidateIfActive(silent: true));
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(venueListViewModelProvider);
    final organizations = ref.watch(organizationsProvider);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
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
              Row(
                children: [
                  const Spacer(),
                  KicksterButton(label: 'Novo', icon: Icons.add, onPressed: () => context.go('/venues/new')),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, vm, organizations)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, VenueListViewModel vm, AsyncValue<List<Organization>> organizations) {
    if (vm.isLoading && vm.venues.isEmpty) {
      return const AppLoading(message: 'Carregando campos...');
    }
    if (vm.errorMessage != null && vm.venues.isEmpty) {
      return AppErrorState(message: 'Não foi possível carregar os campos', onRetry: () => vm.load(forceRefresh: true));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilters(vm),
        const SizedBox(height: 16),
        Expanded(
          child: vm.filteredVenues.isEmpty ? _buildEmptyState(vm) : _buildList(context, vm, organizations),
        ),
      ],
    );
  }

  Widget _buildFilters(VenueListViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: KicksterSearchField(controller: _searchController, hint: 'Buscar por nome...', onChanged: vm.setSearchQuery),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: vm.isRevalidating ? 'Sincronizando...' : 'Atualizar lista',
          child: IconButton(
            icon: vm.isRevalidating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: vm.isRevalidating ? null : () => vm.load(forceRefresh: true),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(VenueListViewModel vm) {
    final hasFilters = vm.searchQuery.isNotEmpty;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.sports_soccer, size: 56, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(hasFilters ? 'Nenhum campo encontrado para os filtros aplicados.' : 'Nenhum campo cadastrado.', style: const TextStyle(color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildList(BuildContext context, VenueListViewModel vm, AsyncValue<List<Organization>> organizations) {
    final list = vm.filteredVenues;
    final orgNames = organizations.valueOrNull ?? const <Organization>[];
    final orgNameById = <String, String>{for (final o in orgNames) o.id: o.tradeName};
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      int crossAxisCount = 1;
      if (width >= 1200) {
        crossAxisCount = 3;
      } else if (width >= 720) {
        crossAxisCount = 2;
      }
      return RefreshIndicator(
        onRefresh: () => vm.load(forceRefresh: true),
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 12, mainAxisSpacing: 12, mainAxisExtent: 96),
          itemCount: list.length,
          itemBuilder: (context, index) => _venueCard(context, list[index], orgNameById),
        ),
      );
    });
  }

  Widget _venueCard(BuildContext context, Venue venue, Map<String, String> orgNameById) {
    final orgName = orgNameById[venue.organizationId] ?? '';
    final subtitle = [if (orgName.isNotEmpty) orgName, if (venue.address != null && venue.address!.isNotEmpty) venue.address!].join(' • ');
    return KicksterCard(icon: Icons.sports_soccer, title: venue.name, subtitle: subtitle.isEmpty ? null : subtitle, onTap: () => context.go('/venues/${venue.id}', extra: venue));
  }
}
