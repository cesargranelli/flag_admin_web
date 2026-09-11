import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flag_admin_web/ui/game/view_models/game_edit_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Argumentos de navegação do formulário de edição de jogo.
typedef GameEditArgs = ({String? roundId, Game? game});

/// Formulário de edição de jogo.
class GameEditScreen extends ConsumerStatefulWidget {
  const GameEditScreen({super.key, required this.gameId, this.args});

  final String gameId;
  final GameEditArgs? args;

  @override
  ConsumerState<GameEditScreen> createState() => _GameEditScreenState();
}

class _GameEditScreenState extends ConsumerState<GameEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late GameEditViewModel _viewModel;
  late final TextEditingController _scheduleController;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(gameEditViewModelProvider(widget.gameId));
    _scheduleController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = widget.args?.game;
      if (game != null) {
        _viewModel.init(game);
        _scheduleController.text = _formatSchedule(_viewModel.scheduledAt);
      }
    });
  }

  @override
  void dispose() {
    _scheduleController.dispose();
    super.dispose();
  }

  String _formatSchedule(DateTime? scheduledAt) {
    return scheduledAt == null
        ? ''
        : '${formatBrDate(scheduledAt)} ${formatBrTime(scheduledAt)}';
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showAppCalendarDialog(
      context,
      initialDate: _viewModel.scheduledAt ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_viewModel.scheduledAt ?? now),
    );
    if (time == null) return;
    final newDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _viewModel.setScheduledAt(newDate);
    _scheduleController.text = _formatSchedule(newDate);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _viewModel.save();
    if (success && mounted) {
      context.go('/games/${widget.gameId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final competitionId = _viewModel.competitionId;
    final rounds = competitionId == null
        ? null
        : ref.watch(roundsProvider(competitionId));
    final teams = competitionId == null
        ? null
        : ref.watch(teamsProvider(competitionId));
    final venues = ref.watch(venuesProvider);

    return AppScreen(
      title: 'Editar jogo',
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.games, route: '/games'),
        BreadcrumbItem('Editar'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLayout.form(
            child: Form(
              key: _formKey,
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      (rounds?.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, s) =>
                                const Text('Erro ao carregar rodadas'),
                            data: (items) => KicksterDropdown<String>(
                              label: 'Rodada',
                              value: _viewModel.roundId,
                              items: items
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r.id,
                                      child: Text(
                                        'Rodada ${r.number} - ${r.name}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  _viewModel.setRoundId(value),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'Selecione a rodada'
                                  : null,
                            ),
                          ) ??
                          const LinearProgressIndicator()),
                      const SizedBox(height: 12),
                      (teams?.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, s) =>
                                const Text('Erro ao carregar times'),
                            data: (items) => KicksterDropdown<String>(
                              label: 'Time da casa',
                              value: _viewModel.homeTeamId,
                              items: items
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text(t.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  _viewModel.setHomeTeamId(value),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'Selecione o time da casa'
                                  : null,
                            ),
                          ) ??
                          const LinearProgressIndicator()),
                      const SizedBox(height: 12),
                      (teams?.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, s) =>
                                const Text('Erro ao carregar times'),
                            data: (items) => KicksterDropdown<String>(
                              label: 'Time visitante',
                              value: _viewModel.awayTeamId,
                              items: items
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text(t.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  _viewModel.setAwayTeamId(value),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione o time visitante';
                                }
                                if (_viewModel.homeTeamId != null &&
                                    value == _viewModel.homeTeamId) {
                                  return 'O time visitante deve ser diferente do time da casa';
                                }
                                return null;
                              },
                            ),
                          ) ??
                          const LinearProgressIndicator()),
                      const SizedBox(height: 12),
                      venues.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) => const Text('Erro ao carregar campos'),
                        data: (items) => KicksterDropdown<String?>(
                          label: 'Campo (opcional)',
                          value: _viewModel.venueId,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Sem campo'),
                            ),
                            ...items.map(
                              (v) => DropdownMenuItem<String?>(
                                value: v.id,
                                child: Text(v.name),
                              ),
                            ),
                          ],
                          onChanged: (value) => _viewModel.setVenueId(value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      KicksterInput(
                        label: 'Horário',
                        controller: _scheduleController,
                        readOnly: true,
                        onTap: _pickSchedule,
                        hintText: 'Selecione data e hora',
                        suffixIcon: const Icon(Icons.schedule),
                      ),
                      if (_viewModel.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _viewModel.errorMessage!,
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                      const SizedBox(height: 24),
                      KicksterButton(
                        label: 'Salvar',
                        icon: Icons.check,
                        loading: _viewModel.isSubmitting,
                        onPressed: _viewModel.isSubmitting ? null : _save,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
