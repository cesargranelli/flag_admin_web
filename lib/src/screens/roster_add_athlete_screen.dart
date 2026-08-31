import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';
import '../widgets/app_screen.dart';

/// Tela para adicionar atletas ao elenco de um time (issue #8).
///
/// Lista todos os atletas da plataforma que ainda não estão no elenco,
/// permitindo incluí-los com apelido e número da camisa.
///
/// Requer [rosterId] para adicionar entradas ao elenco correto.
class RosterAddAthleteScreen extends ConsumerStatefulWidget {
  const RosterAddAthleteScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.rosterId,
  });

  final String teamId;
  final String teamName;
  final String rosterId;

  @override
  ConsumerState<RosterAddAthleteScreen> createState() =>
      _RosterAddAthleteScreenState();
}

class _RosterAddAthleteScreenState
    extends ConsumerState<RosterAddAthleteScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const _addScope = 'roster-add';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addAthlete(Athlete athlete) async {
    // Solicita apelido e número da camisa antes de incluir.
    final details = await _promptRosterDetails(athlete.name);
    if (details == null || !mounted) return;

    await runMutation(
      context,
      ref: ref,
      scope: _addScope,
      action: () => ref.read(rosterApiProvider).add(
            widget.rosterId,
            athleteId: athlete.id,
            nickname: details.nickname,
            number: details.number,
          ),
      successMessage: '${athlete.name} adicionado ao elenco.',
      errorMessage: 'Não foi possível adicionar o atleta.',
      progressId: athlete.id,
      onSuccess: () => ref.invalidate(rosterEntriesProvider(widget.rosterId)),
    );
  }

  /// Diálogo para coletar apelido e número da camisa do atleta ao incluí-lo no
  /// elenco. Retorna `null` quando cancelado.
  Future<({String? nickname, int? number})?> _promptRosterDetails(
    String athleteName,
  ) {
    return showDialog<({String? nickname, int? number})>(
      context: context,
      builder: (_) => _RosterDetailsDialog(athleteName: athleteName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final breadcrumb = [
      const BreadcrumbItem('Início', route: '/'),
      const BreadcrumbItem(AppStrings.teams, route: '/teams'),
      BreadcrumbItem(widget.teamName, route: '/teams/${widget.teamId}'),
      BreadcrumbItem('Elenco', route: '/teams/${widget.teamId}/roster'),
      const BreadcrumbItem('Adicionar atleta'),
    ];

    return AppScreen(
      title: 'Adicionar atleta',
      scrollable: false,
      breadcrumb: breadcrumb,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLayout.content(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: KicksterSearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                hint: 'Buscar atleta',
              ),
            ),
          ),
          Expanded(
            child: _buildAthleteList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteList() {
    final athletesAsync = ref.watch(athletesProvider);
    final rosterAsync = ref.watch(rosterEntriesProvider(widget.rosterId));

    if (athletesAsync.isLoading || rosterAsync.isLoading) {
      return const AppLoading(message: 'Carregando atletas...');
    }
    if (athletesAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar os atletas',
        onRetry: () => ref.invalidate(athletesProvider),
      );
    }
    if (rosterAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar o elenco',
        onRetry: () => ref.invalidate(rosterEntriesProvider(widget.rosterId)),
      );
    }

    final athletes = athletesAsync.value ?? const <Athlete>[];
    final entries = rosterAsync.value ?? const <RosterEntry>[];
    final inRosterIds = {for (final e in entries) e.athleteId};

    // Filtra atletas que já estão no elenco
    final availableAthletes =
        athletes.where((a) => !inRosterIds.contains(a.id)).toList();

    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? availableAthletes
        : availableAthletes
            .where((a) => a.name.toLowerCase().contains(normalizedQuery))
            .toList(growable: false);

    if (availableAthletes.isEmpty) {
      return const KicksterEmptyState(
        icon: Icons.person_outline,
        message: 'Todos os atletas já estão no elenco',
        description: 'Não há mais atletas disponíveis para adicionar.',
      );
    }

    if (filtered.isEmpty) {
      return const AppEmptyState(
        message: 'Nenhum atleta encontrado',
        icon: Icons.search_off,
      );
    }

    return AppLayout.content(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 960
              ? 3
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 80,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final athlete = filtered[index];
              return _athleteCard(context, athlete);
            },
          );
        },
      ),
    );
  }

  /// Card de atleta no estilo Figma (node 34442:3299):
  /// - Background: #ECF1F6 (Grayscale 20)
  /// - Border radius: 12px
  /// - Padding: 4px 10px
  /// - Avatar: 60x60, border radius 16px
  /// - Nome: 14px Medium #111111
  /// - Subtítulo: 12px Regular #9CA4AB
  Widget _athleteCard(BuildContext context, Athlete athlete) {
    final position = athlete.positionsLabel;
    final subtitle = [
      if (athlete.number != null) '#${athlete.number}',
      if (athlete.nickname != null && athlete.nickname!.isNotEmpty)
        athlete.nickname!,
      if (position.isNotEmpty) position,
    ].join(' · ');

    final adding =
        ref.watch(mutationProgressProvider(_addScope)).contains(athlete.id);

    return Card(
      elevation: 0,
      color: AppColors.grayFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            // Avatar 60x60 com border radius 16px
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 60,
                height: 60,
                child: KicksterAvatar(
                  name: athlete.name,
                  imageUrl: athlete.photoUrl,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Nome + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athlete.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Ícone adicionar
            if (adding)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'Adicionar ao elenco',
                icon: const Icon(
                  Icons.person_add_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () => _addAthlete(athlete),
              ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo que coleta apelido e número da camisa ao incluir um atleta no
/// elenco. Retorna um record com os valores preenchidos (ou `null` para
/// campos vazios) e `null` ao cancelar.
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
        ? 'Informe um número válido'
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
              label: 'Número da camisa',
              controller: _numberController,
              keyboardType: TextInputType.number,
              maxLength: 3,
              validator: _validateNumber,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Confirmar')),
      ],
    );
  }
}
