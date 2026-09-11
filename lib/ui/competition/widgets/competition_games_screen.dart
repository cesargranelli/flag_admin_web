import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flag_admin_web/domain/enums/game_status.dart';
import 'package:flag_admin_web/domain/enums/round_type.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/domain/models/game.dart';
import 'package:flag_admin_web/domain/models/round.dart';
import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_games_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tela de Tabelamento & Agendamento de Jogos da Competição (Fase 3).
class CompetitionGamesScreen extends ConsumerStatefulWidget {
  final String competitionId;
  final Competition? competition;

  const CompetitionGamesScreen({
    super.key,
    required this.competitionId,
    this.competition,
  });

  @override
  ConsumerState<CompetitionGamesScreen> createState() =>
      _CompetitionGamesScreenState();
}

class _CompetitionGamesScreenState
    extends ConsumerState<CompetitionGamesScreen> {
  late CompetitionGamesParam _param;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _param = CompetitionGamesParam(
      competitionId: widget.competitionId,
      competition: widget.competition,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(competitionGamesViewModelProvider(_param)).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(competitionGamesViewModelProvider(_param));
    final user = ref.watch(authControllerProvider.select((a) => a.state.user));
    final canWrite = user != null;

    final compName = widget.competition?.displayName ?? 'Competição';

    return AppScreen(
      title: 'Tabelamento: $compName',
      scrollable: false,
      breadcrumb: [
        const BreadcrumbItem(AppStrings.home, route: '/'),
        const BreadcrumbItem('Competições', route: '/competitions'),
        BreadcrumbItem(
          compName,
          route: '/competitions/${widget.competitionId}',
        ),
        const BreadcrumbItem('Tabelamento & Jogos'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              if (canWrite) ...[
                KicksterButton(
                  label: 'Nova Rodada',
                  icon: Icons.format_list_numbered,
                  variant: KicksterButtonVariant.outline,
                  onPressed: () => _showRoundModal(context, vm),
                ),
                const SizedBox(width: 12),
                KicksterButton(
                  label: 'Agendar Jogo',
                  icon: Icons.add,
                  onPressed: () => _showGameModal(context, vm),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody(context, vm, canWrite)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CompetitionGamesViewModel vm,
    bool canWrite,
  ) {
    if (vm.isLoading && vm.games.isEmpty && vm.rounds.isEmpty) {
      return const AppLoading(message: 'Carregando tabelamento...');
    }

    if (vm.errorMessage != null && vm.games.isEmpty && vm.rounds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.errorMessage!,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 12),
            KicksterButton(
              label: 'Tentar novamente',
              onPressed: () => vm.load(forceRefresh: true),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilters(context, vm),
        const SizedBox(height: 16),
        Expanded(
          child: vm.filteredGames.isEmpty
              ? _buildEmptyState(vm, canWrite)
              : _buildList(context, vm, canWrite),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, CompetitionGamesViewModel vm) {
    final roundValues = <String?>[null, ...vm.rounds.map((r) => r.id)];
    final roundLabels = <String>[
      'Todas as Rodadas',
      ...vm.rounds.map((r) => '${r.name} (#${r.number})'),
    ];

    final statusValues = <GameStatus?>[null, ...GameStatus.values];
    final statusLabels = <String>[
      'Todos os Status',
      ...GameStatus.values.map((s) => s.label),
    ];

    return Row(
      children: [
        Expanded(
          child: KicksterSearchField(
            controller: _searchController,
            hint: 'Buscar por equipe ou local...',
            onChanged: vm.setSearchQuery,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 240,
          child: KicksterDropdown<String?>(
            label: '',
            value: vm.selectedRoundId,
            values: roundValues,
            labels: roundLabels,
            onChanged: vm.setSelectedRoundId,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 200,
          child: KicksterDropdown<GameStatus?>(
            label: '',
            value: vm.selectedStatus,
            values: statusValues,
            labels: statusLabels,
            onChanged: vm.setSelectedStatus,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          tooltip: 'Recarregar',
          onPressed: () => vm.load(forceRefresh: true),
        ),
      ],
    );
  }

  Widget _buildEmptyState(CompetitionGamesViewModel vm, bool canWrite) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sports_football_outlined,
            size: 64,
            color: AppColors.disabled,
          ),
          const SizedBox(height: 16),
          Text(
            vm.rounds.isEmpty
                ? 'Nenhuma rodada cadastrada'
                : 'Nenhum jogo agendado',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vm.rounds.isEmpty
                ? 'Comece criando as rodadas ou fases do campeonato.'
                : 'Agende partidas entre as equipes inscritas.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (canWrite)
            KicksterButton(
              label: vm.rounds.isEmpty
                  ? 'Criar Primeira Rodada'
                  : 'Agendar Primeiro Jogo',
              icon: Icons.add,
              onPressed: () {
                if (vm.rounds.isEmpty) {
                  _showRoundModal(context, vm);
                } else {
                  _showGameModal(context, vm);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    CompetitionGamesViewModel vm,
    bool canWrite,
  ) {
    final list = vm.filteredGames;

    return LayoutBuilder(
      builder: (context, constraints) {
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 142,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return _buildGameCard(context, list[index], vm, canWrite);
            },
          ),
        );
      },
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    Game game,
    CompetitionGamesViewModel vm,
    bool canWrite,
  ) {
    final isBusy = vm.actionInProgressId == game.id;
    final round = vm.rounds.where((r) => r.id == game.roundId).firstOrNull;
    final roundName = round != null ? round.name : 'Rodada';

    final dateStr = _formatDateTime(game.scheduledAt);

    final homeName = game.homeTeamName ?? 'Mandante';
    final awayName = game.awayTeamName ?? 'Visitante';
    final venueName = game.venueName ?? 'Local a definir';

    final homeTeam = vm.teams
        .where((t) => t.teamId == game.homeTeamId)
        .firstOrNull;
    final awayTeam = vm.teams
        .where((t) => t.teamId == game.awayTeamId)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roundName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              _buildStatusBadge(game.status),
              if (canWrite) ...[
                const SizedBox(width: 6),
                KicksterMenuAnchor(
                  triggerLabel: 'Ações do Jogo',
                  alignment: Alignment.topRight,
                  width: 200,
                  trigger: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  items: [
                    KicksterMenuItem(
                      child: const Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Editar Jogo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showGameModal(context, vm, game: game),
                    ),
                    KicksterMenuItem(
                      child: const Row(
                        children: [
                          Icon(
                            Icons.published_with_changes,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Alterar Status',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showStatusModal(context, vm, game),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _buildTeamCardSide(
                  teamName: homeName,
                  logoUrl: homeTeam?.teamLogoUrl,
                  shortName: homeTeam?.teamShortName,
                  isHome: true,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (game.status == GameStatus.inProgress ||
                          game.status == GameStatus.finished ||
                          game.status == GameStatus.conference)
                      ? '${game.homeScore ?? 0} x ${game.awayScore ?? 0}'
                      : 'vs',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: game.status == GameStatus.inProgress
                        ? AppColors.success
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: _buildTeamCardSide(
                  teamName: awayName,
                  logoUrl: awayTeam?.teamLogoUrl,
                  shortName: awayTeam?.teamShortName,
                  isHome: false,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  venueName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCardSide({
    required String teamName,
    required String? logoUrl,
    required String? shortName,
    required bool isHome,
  }) {
    final avatarWidget = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: KicksterAvatar(
        imageUrl: (logoUrl != null && logoUrl.trim().isNotEmpty)
            ? logoUrl
            : null,
        name: (shortName != null && shortName.trim().isNotEmpty)
            ? shortName
            : teamName,
        size: 44,
      ),
    );

    return Row(
      mainAxisAlignment: isHome
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isHome) ...[avatarWidget, const SizedBox(width: 10)],
        Flexible(
          child: Text(
            teamName,
            textAlign: isHome ? TextAlign.right : TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (isHome) ...[const SizedBox(width: 10), avatarWidget],
      ],
    );
  }

  Widget _buildStatusBadge(GameStatus status) {
    final (bg, fg) = switch (status) {
      GameStatus.scheduled => (AppColors.surfaceMuted, AppColors.textSecondary),
      GameStatus.open => (
        AppColors.accent.withValues(alpha: 0.15),
        AppColors.accent,
      ),
      GameStatus.inProgress => (
        AppColors.success.withValues(alpha: 0.15),
        AppColors.success,
      ),
      GameStatus.conference => (
        AppColors.warning.withValues(alpha: 0.15),
        AppColors.chipPendingFg,
      ),
      GameStatus.finished => (AppColors.surfaceMuted, AppColors.textPrimary),
      GameStatus.cancelled => (
        AppColors.danger.withValues(alpha: 0.15),
        AppColors.danger,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  void _showRoundModal(
    BuildContext context,
    CompetitionGamesViewModel vm, {
    Round? round,
  }) {
    final isEditing = round != null;
    final nextNumber = isEditing
        ? round.number
        : (vm.rounds.fold<int>(0, (max, r) => r.number > max ? r.number : max) +
              1);

    final numberController = TextEditingController(text: nextNumber.toString());
    final nameController = TextEditingController(
      text: isEditing ? round.name : 'Rodada $nextNumber',
    );
    RoundType selectedType = isEditing ? round.type : RoundType.regular;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEditing ? 'Editar Rodada' : 'Nova Rodada / Fase',
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KicksterInput(
                  controller: numberController,
                  label: 'Número da Rodada',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                KicksterInput(
                  controller: nameController,
                  label: 'Nome da Rodada / Fase',
                  hintText: 'Ex: Rodada 1, Quartas de Final, Semifinal...',
                ),
                const SizedBox(height: 16),
                KicksterDropdown<RoundType>(
                  label: 'Tipo de Rodada',
                  value: selectedType,
                  values: RoundType.values,
                  labels: RoundType.values.map((t) => t.label).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedType = val);
                    }
                  },
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
              label: isEditing ? 'Salvar Alterações' : 'Criar Rodada',
              onPressed: () async {
                final number = int.tryParse(numberController.text.trim()) ?? 1;
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                Navigator.of(dialogCtx).pop();
                if (isEditing) {
                  await vm.updateRound(
                    id: round.id,
                    number: number,
                    name: name,
                    type: selectedType,
                  );
                } else {
                  await vm.createRound(
                    number: number,
                    name: name,
                    type: selectedType,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGameModal(
    BuildContext context,
    CompetitionGamesViewModel vm, {
    Game? game,
  }) {
    if (vm.rounds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crie pelo menos uma rodada antes de agendar jogos.'),
        ),
      );
      _showRoundModal(context, vm);
      return;
    }

    if (vm.teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inscreva pelo menos 2 equipes esportivas na competição para agendar confrontos.',
          ),
        ),
      );
      return;
    }

    final isEditing = game != null;

    String selectedRoundId = isEditing
        ? game.roundId
        : (vm.selectedRoundId ?? vm.rounds.first.id);

    String selectedHomeTeamId = isEditing
        ? (game.homeTeamId ?? vm.teams.first.teamId)
        : vm.teams.first.teamId;

    String selectedAwayTeamId = isEditing
        ? (game.awayTeamId ??
              (vm.teams.length > 1
                  ? vm.teams[1].teamId
                  : vm.teams.first.teamId))
        : (vm.teams.length > 1 ? vm.teams[1].teamId : vm.teams.first.teamId);

    String? selectedVenueId = isEditing
        ? game.venueId
        : (vm.venues.isNotEmpty ? vm.venues.first.id : null);

    DateTime selectedDate = isEditing
        ? game.scheduledAt
        : DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = isEditing
        ? TimeOfDay(
            hour: game.scheduledAt.hour,
            minute: game.scheduledAt.minute,
          )
        : const TimeOfDay(hour: 14, minute: 0);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final compName = widget.competition?.displayName ?? 'Competição';
          final orgName = widget.competition?.organizationName ?? '';
          final selectedHomeTeam = vm.teams
              .where((t) => t.teamId == selectedHomeTeamId)
              .firstOrNull;
          final selectedAwayTeam = vm.teams
              .where((t) => t.teamId == selectedAwayTeamId)
              .firstOrNull;

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              isEditing ? 'Editar Confronto' : 'Agendar Confronto',
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dados fixos (Campeonato e Organização Promotora)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Campeonato',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        compName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (orgName.isNotEmpty) ...[
                            Container(
                              width: 1,
                              height: 30,
                              color: AppColors.line,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Organização',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.business_outlined,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          orgName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    KicksterDropdown<String>(
                      label: 'Rodada / Fase',
                      value: selectedRoundId,
                      values: vm.rounds.map((r) => r.id).toList(),
                      labels: vm.rounds
                          .map((r) => '${r.name} (#${r.number})')
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => selectedRoundId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              KicksterDropdown<String>(
                                label: 'Equipe Mandante',
                                value: selectedHomeTeamId,
                                values: vm.teams.map((t) => t.teamId).toList(),
                                labels: vm.teams
                                    .map((t) => t.teamName)
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      selectedHomeTeamId = val;
                                      if (selectedAwayTeamId == val) {
                                        final other = vm.teams.firstWhere(
                                          (t) => t.teamId != val,
                                          orElse: () => vm.teams.first,
                                        );
                                        selectedAwayTeamId = other.teamId;
                                      }
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Agremiação / Clube',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            selectedHomeTeam
                                                    ?.resolvedInstitutionName ??
                                                'Não vinculada',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              KicksterDropdown<String>(
                                label: 'Equipe Visitante',
                                value: selectedAwayTeamId,
                                values: vm.teams
                                    .where(
                                      (t) => t.teamId != selectedHomeTeamId,
                                    )
                                    .map((t) => t.teamId)
                                    .toList(),
                                labels: vm.teams
                                    .where(
                                      (t) => t.teamId != selectedHomeTeamId,
                                    )
                                    .map((t) => t.teamName)
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setModalState(
                                      () => selectedAwayTeamId = val,
                                    );
                                },
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Agremiação / Clube',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            selectedAwayTeam
                                                    ?.resolvedInstitutionName ??
                                                'Não vinculada',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    KicksterDropdown<String?>(
                      label: 'Local / Praça Esportiva',
                      value: selectedVenueId,
                      values: [null, ...vm.venues.map((v) => v.id)],
                      labels: [
                        'Local a definir',
                        ...vm.venues.map((v) => v.name),
                      ],
                      onChanged: (val) =>
                          setModalState(() => selectedVenueId = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data da Partida',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked =
                                      await showKicksterCalendarDialog(
                                        ctx,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                  if (picked != null) {
                                    setModalState(() => selectedDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.line),
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.surface,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _formatDate(selectedDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Horário de Início',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: ctx,
                                    initialTime: selectedTime,
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedTime = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.line),
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.surface,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              KicksterButton(
                label: 'Cancelar',
                variant: KicksterButtonVariant.text,
                onPressed: () => Navigator.of(dialogCtx).pop(),
              ),
              KicksterButton(
                label: isEditing ? 'Salvar Jogo' : 'Confirmar Agendamento',
                onPressed: () async {
                  if (selectedHomeTeamId == selectedAwayTeamId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'A equipe mandante e a equipe visitante não podem ser a mesma equipe esportiva.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.of(dialogCtx).pop();

                  final scheduledDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  if (isEditing) {
                    await vm.updateGame(
                      id: game.id,
                      roundId: selectedRoundId,
                      homeTeamId: selectedHomeTeamId,
                      awayTeamId: selectedAwayTeamId,
                      venueId: selectedVenueId,
                      scheduledAt: scheduledDateTime,
                    );
                  } else {
                    await vm.createGame(
                      roundId: selectedRoundId,
                      homeTeamId: selectedHomeTeamId,
                      awayTeamId: selectedAwayTeamId,
                      venueId: selectedVenueId,
                      scheduledAt: scheduledDateTime,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatusModal(
    BuildContext context,
    CompetitionGamesViewModel vm,
    Game game,
  ) {
    GameStatus currentStatus = game.status;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Alterar Status da Partida',
            style: AppTextStyles.labelMedium.copyWith(
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
                Text(
                  'Confronto: ${game.homeTeamName ?? 'Mandante'} x ${game.awayTeamName ?? 'Visitante'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                KicksterDropdown<GameStatus>(
                  label: 'Novo Status',
                  value: currentStatus,
                  values: GameStatus.values,
                  labels: GameStatus.values.map((s) => s.label).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => currentStatus = val);
                  },
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
              label: 'Atualizar Status',
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await vm.updateGameStatus(id: game.id, status: currentStatus);
              },
            ),
          ],
        ),
      ),
    );
  }
}
