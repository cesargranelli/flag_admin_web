import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/person/view_models/roster_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Elenco de um clube (time) numa competicao.
///
/// A tela combina o [RosterViewModel] (pessoas + elenco do time) e permite
/// incluir e remover pessoas do elenco.
class RosterScreen extends ConsumerStatefulWidget {
  const RosterScreen({super.key, this.team, this.teamId});

  final dynamic team;
  final String? teamId;

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  final TextEditingController _searchController = TextEditingController();
  late RosterViewModel _vm;

  @override
  void initState() {
    super.initState();
    final teamId = widget.team?.id ?? widget.teamId;
    if (teamId != null) {
      _vm = RosterViewModel(
        rosterRepository: ref.read(rosterRepositoryProvider),
        personRepository: ref.read(personRepositoryProvider),
        teamId: teamId,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _vm.load(forceRefresh: true);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addPerson(dynamic person) async {
    final details = await showDialog<({String? nickname, int? number})>(
      context: context,
      builder: (_) => _RosterDetailsDialog(personName: person.name),
    );
    if (details == null || !mounted) return;

    final ok = await _vm.addPerson(
      person: person,
      nickname: details.nickname,
      number: details.number,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${person.name} adicionado ao elenco.')),
      );
    } else if (_vm.mutationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel adicionar a pessoa.')),
      );
    }
  }

  Future<void> _removePerson(dynamic entry) async {
    final ok = await _vm.removePerson(entry);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.athleteName} removido do elenco.')),
      );
    } else if (_vm.mutationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel remover a pessoa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = widget.team?.id ?? widget.teamId;
    final teamName = widget.team?.name;
    final title = teamName ?? 'Elenco';

    final breadcrumb = [
      const BreadcrumbItem(AppStrings.home, route: '/'),
      const BreadcrumbItem(AppStrings.rosters, route: '/rosters'),
      if (teamName != null) BreadcrumbItem(teamName),
      const BreadcrumbItem('Elenco'),
    ];

    return AppScreen(
      title: title,
      scrollable: false,
      breadcrumb: breadcrumb,
      body: teamId == null
          ? const AppEmptyState(
              message: 'Time nao identificado',
              icon: Icons.groups_outlined,
            )
          : ListenableBuilder(
              listenable: _vm,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        tooltip: 'Importar CSV',
                        icon: const Icon(Icons.upload_file),
                        onPressed: () =>
                            context.push('/rosters/import', extra: teamId),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Recarregar elenco',
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _vm.load(forceRefresh: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildBody(context)),
                ],
              ),
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_vm.isLoadingRoster || _vm.isLoadingPersons) {
      return const AppLoading(message: 'Carregando pessoas...');
    }

    if (_vm.rosterError != null) {
      return AppErrorState(
        message: 'Nao foi possivel carregar o elenco',
        onRetry: () => _vm.load(forceRefresh: true),
      );
    }

    if (_vm.personsError != null) {
      return AppErrorState(
        message: 'Nao foi possivel carregar as pessoas',
        onRetry: () => _vm.load(forceRefresh: true),
      );
    }

    final persons = _vm.persons;
    final roster = _vm.roster;
    final inRosterIds = {for (final e in roster) e.athleteId};
    final entryByAthleteId = {for (final e in roster) e.athleteId: e};

    final filtered = _vm.filteredPersons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLayout.content(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: KicksterSearchField(
              controller: _searchController,
              onChanged: (value) => _vm.setSearchQuery(value),
              hint: 'Buscar pessoa por nome',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildList(
            persons: persons,
            filtered: filtered,
            inRosterIds: inRosterIds,
            entryByAthleteId: entryByAthleteId,
          ),
        ),
      ],
    );
  }

  Widget _buildList({
    required List<dynamic> persons,
    required List<dynamic> filtered,
    required Set<String> inRosterIds,
    required Map<String, dynamic> entryByAthleteId,
  }) {
    if (persons.isEmpty) {
      return KicksterEmptyState(
        icon: Icons.person_outline,
        message: 'Nenhuma pessoa cadastrada',
        description: 'Cadastre pessoas na plataforma para inclui-las no elenco.',
        action: KicksterButton(
          label: 'Cadastrar pessoa',
          icon: Icons.add,
          onPressed: () => context.go('/persons/new'),
        ),
      );
    }
    if (filtered.isEmpty) {
      return const AppEmptyState(
        message: 'Nenhuma pessoa encontrada',
        icon: Icons.search_off,
      );
    }

    final allInRoster = persons.every((a) => inRosterIds.contains(a.id));
    final showAllNote = allInRoster && _vm.searchQuery.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAllNote)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Todas as pessoas ja estao no elenco',
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
                final person = filtered[index];
                final inRoster = inRosterIds.contains(person.id);
                return _personCard(
                  context,
                  person,
                  inRoster: inRoster,
                  entry: inRoster ? entryByAthleteId[person.id] : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _personCard(
    BuildContext context,
    dynamic person, {
    required bool inRoster,
    required dynamic entry,
  }) {
    final displayNickname = inRoster && entry != null ? entry.nickname : null;
    final displayNumber = inRoster && entry != null ? entry.number : null;
    final roleLabel = person.roleLabel;
    final subtitle = [
      if (displayNumber != null) '#$displayNumber',
      if (displayNickname != null && displayNickname.isNotEmpty)
        displayNickname,
      if (roleLabel.isNotEmpty) roleLabel,
    ].join(' ');

    final adding = _vm.addingAthleteIds.contains(person.id);
    final removing = _vm.removingAthleteIds.contains(person.id);

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
              name: person.name,
              imageUrl: person.photoUrl,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    person.name,
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
                    tooltip: 'Remover pessoa',
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed:
                        entry == null ? null : () => _removePerson(entry),
                  ),
                ],
              )
            else
              KicksterButton(
                label: 'Incluir',
                variant: KicksterButtonVariant.outline,
                onPressed: () => _addPerson(person),
              ),
          ],
        ),
      ),
    );
  }
}

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

class _RosterDetailsDialog extends StatefulWidget {
  const _RosterDetailsDialog({required this.personName});

  final String personName;

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
      title: Text('Incluir ${widget.personName}'),
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
