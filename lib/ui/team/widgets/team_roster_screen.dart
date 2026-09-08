import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/team/view_models/team_roster_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tela de Gestao de Elenco de um time (ADR-001 / MVVM).
///
/// Exibe todos os atletas cadastrados na plataforma e permite
/// incluir ou remover atletas do elenco-base do time.
class TeamRosterScreen extends ConsumerStatefulWidget {
  const TeamRosterScreen({
    super.key,
    required this.teamId,
    this.team,
  });

  /// Id do time (extraido da rota `/teams/:id/roster`).
  final String teamId;

  /// Time passado via `state.extra` — usado apenas para o breadcrumb/titulo.
  final Team? team;

  @override
  ConsumerState<TeamRosterScreen> createState() => _TeamRosterScreenState();
}

class _TeamRosterScreenState extends ConsumerState<TeamRosterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late TeamRosterViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = TeamRosterViewModel(
      rosterApi: ref.read(rosterApiProvider),
      teamId: widget.teamId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.loadRoster();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Solicita apelido/numero antes de adicionar ao elenco.
  Future<void> _addAthlete(Athlete athlete) async {
    final details = await showDialog<({String? nickname, int? number})>(
      context: context,
      builder: (_) => _RosterDetailsDialog(athleteName: athlete.name),
    );
    if (details == null || !mounted) return;

    final ok = await _vm.addAthlete(
      athlete: athlete,
      nickname: details.nickname,
      number: details.number,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${athlete.name} adicionado ao elenco.')),
      );
    } else if (_vm.mutationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel adicionar o atleta.')),
      );
    }
  }

  /// Remove um atleta do elenco com confirmacao.
  Future<void> _removeAthlete(RosterEntry entry) async {
    final ok = await _vm.removeAthlete(entry);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.athleteName} removido do elenco.')),
      );
    } else if (_vm.mutationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel remover o atleta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamName = widget.team?.name;
    final title = teamName ?? 'Elenco';

    final breadcrumb = [
      const BreadcrumbItem(AppStrings.home, route: '/'),
      const BreadcrumbItem(AppStrings.institutions, route: '/institutions'),
      if (teamName != null) BreadcrumbItem(teamName),
      const BreadcrumbItem('Elenco'),
    ];

    return AppScreen(
      title: title,
      scrollable: false,
      breadcrumb: breadcrumb,
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de acoes superior
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    tooltip: 'Importar CSV',
                    icon: const Icon(Icons.upload_file),
                    onPressed: () =>
                        context.push('/rosters/import', extra: widget.teamId),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Recarregar elenco',
                    icon: const Icon(Icons.refresh),
                    onPressed: _vm.loadRoster,
                  ),
                ],
              ),
            ),
            // Corpo principal
            Expanded(
              child: _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final athletesAsync = ref.watch(athletesProvider);

    if (_vm.isLoadingRoster || athletesAsync.isLoading) {
      return const AppLoading(message: 'Carregando atletas...');
    }

    if (_vm.rosterError != null) {
      return AppErrorState(
        message: 'Nao foi possivel carregar o elenco',
        onRetry: _vm.loadRoster,
      );
    }

    if (athletesAsync.hasError) {
      return AppErrorState(
        message: 'Nao foi possivel carregar os atletas',
        onRetry: () => ref.invalidate(athletesProvider),
      );
    }

    final athletes = athletesAsync.value ?? const <Athlete>[];
    final roster = _vm.roster;
    final inRosterIds = {for (final e in roster) e.athleteId};
    final entryByAthleteId = {for (final e in roster) e.athleteId: e};

    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = athletes
        .where(
          (a) =>
              normalizedQuery.isEmpty ||
              a.name.toLowerCase().contains(normalizedQuery),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra de busca
        AppLayout.content(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: KicksterSearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              hint: 'Buscar atleta por nome',
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Lista de atletas
        Expanded(
          child: _buildList(
            athletes: athletes,
            filtered: filtered,
            inRosterIds: inRosterIds,
            entryByAthleteId: entryByAthleteId,
          ),
        ),
      ],
    );
  }

  Widget _buildList({
    required List<Athlete> athletes,
    required List<Athlete> filtered,
    required Set<String> inRosterIds,
    required Map<String, RosterEntry> entryByAthleteId,
  }) {
    if (athletes.isEmpty) {
      return KicksterEmptyState(
        icon: Icons.person_outline,
        message: 'Nenhum atleta cadastrado',
        description:
            'Cadastre atletas na plataforma para incluí-los no elenco.',
        action: KicksterButton(
          label: 'Cadastrar atleta',
          icon: Icons.add,
          onPressed: () => context.go('/athletes/new'),
        ),
      );
    }
    if (filtered.isEmpty) {
      return const AppEmptyState(
        message: 'Nenhum atleta encontrado',
        icon: Icons.search_off,
      );
    }

    final allInRoster = athletes.every((a) => inRosterIds.contains(a.id));
    final showAllNote = allInRoster && _query.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAllNote)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Todos os atletas já estão no elenco',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        Expanded(
          child: AppLayout.content(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final athlete = filtered[index];
                final inRoster = inRosterIds.contains(athlete.id);
                return _athleteCard(
                  context,
                  athlete,
                  inRoster: inRoster,
                  entry: inRoster ? entryByAthleteId[athlete.id] : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _athleteCard(
    BuildContext context,
    Athlete athlete, {
    required bool inRoster,
    required RosterEntry? entry,
  }) {
    final rosterNickname = inRoster && entry != null
        ? (entry.nickname ?? entry.athleteNickname)
        : null;
    final displayNickname = rosterNickname ?? athlete.nickname;
    final displayNumber =
        inRoster && entry != null ? entry.number : athlete.number;
    final position = athlete.positionsLabel;
    final subtitle = [
      if (displayNumber != null) '#$displayNumber',
      if (displayNickname != null && displayNickname.isNotEmpty)
        displayNickname,
      if (position.isNotEmpty) position,
    ].join(' · ');

    final adding = _vm.addingAthleteIds.contains(athlete.id);
    final removing = _vm.removingAthleteIds.contains(athlete.id);

    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          children: [
            KicksterAvatar(
              name: athlete.name,
              imageUrl: athlete.photoUrl,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    athlete.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
            if (adding || removing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (inRoster)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _InRosterBadge(),
                  IconButton(
                    tooltip: 'Remover atleta',
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed:
                        entry == null ? null : () => _removeAthlete(entry),
                  ),
                ],
              )
            else
              KicksterButton(
                label: 'Incluir',
                variant: KicksterButtonVariant.outline,
                onPressed: () => _addAthlete(athlete),
              ),
          ],
        ),
      ),
    );
  }
}

/// Badge visual de atleta ja inscrito no elenco.
class _InRosterBadge extends StatelessWidget {
  const _InRosterBadge();

  @override
  Widget build(BuildContext context) {
    return const KicksterBadge(
      label: 'No elenco',
      color: AppColors.success,
      icon: Icons.check_circle,
    );
  }
}

/// Dialogo para coletar apelido e numero da camisa ao incluir no elenco.
///
/// Retorna um record com os valores preenchidos, ou `null` ao cancelar.
class _RosterDetailsDialog extends StatefulWidget {
  const _RosterDetailsDialog({required this.athleteName});

  final String athleteName;

  @override
  State<_RosterDetailsDialog> createState() => _RosterDetailsDialogState();
}

class _RosterDetailsDialogState extends State<_RosterDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _numberController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value.trim()) == null
        ? 'Informe um numero valido'
        : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final nickname = _nicknameController.text.trim();
    final numberText = _numberController.text.trim();
    Navigator.of(context).pop((
      nickname: nickname.isEmpty ? null : nickname,
      number: numberText.isEmpty ? null : int.parse(numberText),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Incluir ${widget.athleteName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KicksterInput(
              label: 'Apelido',
              controller: _nicknameController,
              maxLength: 100,
              hintText: 'Ex.: "Veloz"',
            ),
            const SizedBox(height: 12),
            KicksterInput(
              label: 'Numero da camisa',
              controller: _numberController,
              keyboardType: TextInputType.number,
              maxLength: 3,
              validator: _validateNumber,
            ),
          ],
        ),
      ),
      actions: [
        KicksterButton(
          label: 'Cancelar',
          variant: KicksterButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        KicksterButton(
          label: 'Confirmar',
          onPressed: _submit,
        ),
      ],
    );
  }
}
