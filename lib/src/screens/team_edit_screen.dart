import 'package:flag_admin_web/src/api/flag_api.dart';
import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Formulário de edição de time (#12).
///
/// Hidrata os campos a partir do [team] (extra da rota) ou, na ausência,
/// carrega via `teamProvider(teamId)`. Campos: nome (obrigatório), sigla e
/// URL do logo. Após salvar, invalida os providers afetados, mostra snackbar
/// de sucesso e volta ao detalhe do time.
class TeamEditScreen extends ConsumerStatefulWidget {
  const TeamEditScreen({super.key, this.teamId, this.team});

  final String? teamId;
  final Team? team;

  @override
  ConsumerState<TeamEditScreen> createState() => _TeamEditScreenState();
}

class _TeamEditScreenState extends ConsumerState<TeamEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _shortName;
  late final TextEditingController _logoUrl;
  bool _submitting = false;
  String? _errorMessage;

  /// Time em edição (extra da rota ou resolvido pelo provider).
  Team? _team;

  /// Guard de hidratação: aplica os valores do provider apenas uma vez.
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _shortName = TextEditingController();
    _logoUrl = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _shortName.dispose();
    _logoUrl.dispose();
    super.dispose();
  }

  /// Hidrata os controllers a partir do time (uma única vez).
  void _hydrate(Team team) {
    if (_hydrated) return;
    _team = team;
    _name.text = team.name;
    _shortName.text = team.shortName ?? '';
    _logoUrl.text = team.logoUrl ?? '';
    _hydrated = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final team = _team;
    if (team == null) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(teamApiProvider);
      final updated = await api.update(
        team.id,
        name: _name.text.trim(),
        shortName: _shortName.text.trim().isEmpty
            ? null
            : _shortName.text.trim(),
        logoUrl: _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
      );
      ref.invalidate(teamProvider(team.id));
      ref.invalidate(clubTeamsProvider(team.organizationId));
      // Se o time aparece na listagem do campeonato efetivo, atualiza.
      final effectiveComp = ref.read(effectiveCompetitionProvider);
      if (effectiveComp != null) ref.invalidate(teamsProvider(effectiveComp));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time salvo com sucesso')),
        );
        context.go('/teams/${team.id}', extra: updated);
      }
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar o time.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateLogoUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    final valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Informe uma URL válida (http/https)';
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.team;

    // Extra da rota já traz o time: hidrata e monta o formulário direto.
    if (team != null) {
      _hydrate(team);
      return _buildForm(context);
    }

    // Sem extra: carrega pelo id (loading/error/data).
    final teamId = widget.teamId!;
    final asyncTeam = ref.watch(teamProvider(teamId));
    return asyncTeam.when(
      loading: () => _buildScaffold(
        body: const AppLoading(message: 'Carregando time...'),
      ),
      error: (error, stackTrace) => _buildScaffold(
        body: AppErrorState(
          message: 'Não foi possível carregar o time',
          onRetry: () => ref.invalidate(teamProvider(teamId)),
        ),
      ),
      data: (t) {
        _hydrate(t);
        return _buildForm(context);
      },
    );
  }

  /// Scaffold padrão para os estados de loading/erro (sem formulário).
  Widget _buildScaffold({required Widget body}) {
    return AppScreen(
      title: 'Editar time',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.teams, route: '/teams'),
        BreadcrumbItem('Editar'),
      ],
      body: body,
    );
  }

  Widget _buildForm(BuildContext context) {
    return AppScreen(
      title: 'Editar time',
      breadcrumb: [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.teams, route: '/teams'),
        if (_team?.name.isNotEmpty ?? false) BreadcrumbItem(_team!.name),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLayout.form(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KicksterInput(
                    label: 'Nome',
                    controller: _name,
                    maxLength: 100,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  KicksterInput(
                    label: 'Sigla',
                    controller: _shortName,
                    maxLength: 10,
                    hintText: 'Ex.: FLA',
                  ),
                  const SizedBox(height: 12),
                  KicksterInput(
                    label: 'URL do logo',
                    controller: _logoUrl,
                    keyboardType: TextInputType.url,
                    hintText: 'Ex.: https://...',
                    validator: _validateLogoUrl,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  KicksterButton(
                    label: 'Salvar',
                    icon: Icons.check,
                    loading: _submitting,
                    onPressed: _submitting ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}