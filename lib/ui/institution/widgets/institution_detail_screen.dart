import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/institution/view_models/institution_detail_view_model.dart';

/// Tela de detalhes de agremiação com Hero Card Esportivo Kickster (ADR-001 / MVVM).
class InstitutionDetailScreen extends ConsumerStatefulWidget {
  final String id;
  final Institution? institution;

  const InstitutionDetailScreen({
    super.key,
    required this.id,
    this.institution,
  });

  @override
  ConsumerState<InstitutionDetailScreen> createState() =>
      _InstitutionDetailScreenState();
}

class _InstitutionDetailScreenState
    extends ConsumerState<InstitutionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(institutionDetailViewModelProvider(widget.id)).load(forceRefresh: true);
    });
  }

  Color? _parseHex(String? text) {
    if (text == null) return null;
    var raw = text.trim();
    if (raw.isEmpty) return null;
    if (!raw.startsWith('#')) raw = '#$raw';
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(raw)) return null;
    try {
      return Color(int.parse('0xFF${raw.substring(1)}'));
    } catch (_) {
      return null;
    }
  }

  Widget _buildLogoFallback(Institution inst, Color primary) {
    final initials = inst.abbreviation?.isNotEmpty == true
        ? inst.abbreviation!.toUpperCase()
        : (inst.tradeName.isNotEmpty
            ? inst.tradeName.substring(0, 1).toUpperCase()
            : 'A');
    return Container(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSwatchBadge(Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(institutionDetailViewModelProvider(widget.id));
    final inst = vm.institution ?? widget.institution;
    final orgsAsync = ref.watch(organizationsProvider);

    final instName = inst?.tradeName.isNotEmpty == true ? inst!.tradeName : inst?.name;
    final breadcrumb = [
      const BreadcrumbItem(AppStrings.home, route: '/'),
      const BreadcrumbItem(AppStrings.institutions, route: '/institutions'),
      if (instName != null) BreadcrumbItem(instName),
    ];

    Widget body;
    if (inst != null) {
      body = _buildDetail(context, vm, inst, orgsAsync);
    } else if (vm.isLoading) {
      body = const AppLoading(message: 'Carregando agremiação...');
    } else if (vm.errorMessage != null) {
      body = AppErrorState(
        message: 'Não foi possível carregar a agremiação',
        onRetry: () => vm.load(forceRefresh: true),
      );
    } else {
      body = const SizedBox.shrink();
    }

    return AppScreen(
      title: instName ?? 'Agremiação',
      breadcrumb: breadcrumb,
      body: body,
    );
  }

  Widget _buildDetail(
    BuildContext context,
    InstitutionDetailViewModel vm,
    Institution inst,
    AsyncValue<List<dynamic>> orgsAsync,
  ) {
    return AppLayout.detail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ações superiores
          Row(
            children: [
              const Spacer(),
              KicksterButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: () async {
                  await context.push(
                    '/institutions/${inst.id}/edit',
                    extra: inst,
                  );
                  if (context.mounted) {
                    ref
                        .read(institutionDetailViewModelProvider(widget.id))
                        .load(forceRefresh: true);
                    ref
                        .read(institutionViewModelProvider)
                        .load(forceRefresh: true);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Seção 1: Card Hero Esportivo de Identificação
          _section(
            title: 'Identificação',
            icon: Icons.shield_outlined,
            child: _heroCard(inst),
          ),

          // Seção 2: Representação & Diretoria
          _section(
            title: 'Representação & Diretoria',
            icon: Icons.person_outline,
            child: _diretoriaCard(inst),
          ),

          // Seção 3: Contato & Redes
          _section(
            title: 'Contato & Redes',
            icon: Icons.contact_mail_outlined,
            child: _contatoCard(inst),
          ),

          // Seção 4: Localização
          _section(
            title: 'Localização',
            icon: Icons.location_on_outlined,
            child: _localizacaoCard(inst),
          ),

          // Seção 5: Filiação a Organizações
          _section(
            title: 'Filiação a Organizações',
            icon: Icons.account_balance_outlined,
            child: _filiacoesCard(inst, orgsAsync),
          ),

          // Seção 6: Equipes Esportivas (ao final)
          _section(
            title: 'Equipes Esportivas',
            icon: Icons.sports_football_outlined,
            child: _teamsSection(context, vm),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(title: title, icon: icon, action: action),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _heroCard(Institution inst) {
    final primary = _parseHex(inst.primaryColor) ??
        (inst.colors.isNotEmpty ? _parseHex(inst.colors[0]) : null) ??
        AppColors.primary;
    final secondary = _parseHex(inst.secondaryColor) ??
        (inst.colors.length > 1 ? _parseHex(inst.colors[1]) : null) ??
        const Color(0xFF1E293B);
    final tertiary = _parseHex(inst.tertiaryColor) ??
        (inst.colors.length > 2 ? _parseHex(inst.colors[2]) : null);
    final quaternary = _parseHex(inst.quaternaryColor) ??
        (inst.colors.length > 3 ? _parseHex(inst.colors[3]) : null);

    final isLightPrimary = primary.computeLuminance() > 0.55;
    final bannerTextColor = isLightPrimary ? AppColors.black : Colors.white;

    return Card(
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Superior com Gradiente
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  Color.lerp(primary, secondary, 0.5) ?? secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSwatchBadge(primary, 'Cor primária'),
                    const SizedBox(width: 6),
                    _buildSwatchBadge(secondary, 'Cor secundária'),
                    if (tertiary != null) ...[
                      const SizedBox(width: 6),
                      _buildSwatchBadge(tertiary, 'Cor terciária'),
                    ],
                    if (quaternary != null) ...[
                      const SizedBox(width: 6),
                      _buildSwatchBadge(quaternary, 'Cor quaternária'),
                    ],
                  ],
                ),
                if (inst.abbreviation != null && inst.abbreviation!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bannerTextColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: bannerTextColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      inst.abbreviation!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: bannerTextColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Area de Identidade com Avatar Hero de 88px
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: inst.logoUrl != null &&
                                inst.logoUrl!.isNotEmpty
                            ? Image.network(
                                inst.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildLogoFallback(inst, primary),
                              )
                            : _buildLogoFallback(inst, primary),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inst.tradeName.isNotEmpty ? inst.tradeName : inst.name,
                            style: AppTextStyles.headline1.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (inst.legalName.isNotEmpty &&
                              inst.legalName != inst.tradeName) ...[
                            const SizedBox(height: 2),
                            Text(
                              inst.legalName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Chip(
                                avatar: Icon(
                                  institutionTypeIcon(inst.type),
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                label: Text(inst.type.label),
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.08),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                labelStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  inst.status == 'INACTIVE' ? 'Inativo' : 'Ativo',
                                ),
                                backgroundColor: inst.status == 'INACTIVE'
                                    ? AppColors.surfaceMuted
                                    : AppColors.success.withValues(alpha: 0.12),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: inst.status == 'INACTIVE'
                                      ? AppColors.textSecondary
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.line),
                const SizedBox(height: 12),
                _fieldRow('Tipo', inst.type.label),
                if (inst.abbreviation != null && inst.abbreviation!.isNotEmpty)
                  _fieldRow('Sigla', inst.abbreviation!),
                if (inst.document != null && inst.document!.isNotEmpty)
                  _fieldRow(
                    inst.documentType?.label ?? 'Documento',
                    inst.document!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diretoriaCard(Institution inst) {
    return _infoCard([
      _fieldRow('Nome do Presidente / Representante', inst.presidentName),
      _fieldRow('CPF do Presidente', inst.presidentCpf),
    ]);
  }

  Widget _contatoCard(Institution inst) {
    return _infoCard([
      _fieldRow('E-mail Oficial', inst.email),
      _fieldRow('Telefone / WhatsApp', inst.phone),
      _fieldRow('Site Oficial', inst.website),
      _fieldRow('Instagram', inst.instagram),
    ]);
  }

  Widget _localizacaoCard(Institution inst) {
    return _infoCard([
      _fieldRow('Cidade', inst.city),
      _fieldRow('Estado (UF)', inst.state),
      _fieldRow('País', inst.country),
    ]);
  }

  Widget _filiacoesCard(Institution inst, AsyncValue<List<dynamic>> orgsAsync) {
    return Card(
      elevation: 1,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: orgsAsync.when(
          data: (orgs) {
            final affiliated = orgs.where((o) => inst.organizations.contains(o.id)).toList();
            if (affiliated.isEmpty) {
              return const Text(
                'Esta agremiação ainda não possui filiação a organizações (ligas ou federações).',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: affiliated.map((org) {
                return ActionChip(
                  avatar: Icon(
                    organizationTypeIcon(org.organizationType),
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(org.tradeName.isNotEmpty ? org.tradeName : org.legalName),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: const BorderSide(color: AppColors.line),
                  onPressed: () => context.push('/organizations/${org.id}', extra: org),
                );
              }).toList(),
            );
          },
          loading: () => const AppLoading(),
          error: (err, _) => Text(
            'Erro ao carregar organizações: $err',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.06),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _fieldRow(String label, String? value) {
    final display = (value == null || value.trim().isEmpty) ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamsSection(BuildContext context, InstitutionDetailViewModel vm) {
    if (vm.isLoadingTeams) {
      return const AppLoading(message: 'Carregando equipes esportivas...');
    }

    if (vm.teamsErrorMessage != null && vm.teams.isEmpty) {
      return AppErrorState(
        message: 'Não foi possível carregar as equipes',
        onRetry: () => vm.loadTeams(forceRefresh: true),
      );
    }

    final teams = vm.teams;

    return Card(
      elevation: 1,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho interno do Card seguindo o padrão Kickster de competições
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Equipes Cadastradas (${teams.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                KicksterButton(
                  label: 'Nova Equipe',
                  icon: Icons.add,
                  variant: KicksterButtonVariant.outline,
                  onPressed: () => _showCreateTeamModal(context, vm),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (teams.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.line.withValues(alpha: 0.8),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhuma equipe cadastrada nesta agremiação.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cadastre as diferentes equipes ou formações deste clube utilizando o botão acima.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 700 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: teams.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 100,
                    ),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return _teamCard(context, vm, team);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _teamCard(
    BuildContext context,
    InstitutionDetailViewModel vm,
    Team team,
  ) {
    final isInactive = team.status == 'INACTIVE';
    final subtitleParts = <String>[];
    if (team.shortName?.isNotEmpty == true) {
      subtitleParts.add('Sigla: ${team.shortName!}');
    }
    if (team.sportName?.isNotEmpty == true) {
      subtitleParts.add(team.sportName!);
    } else {
      subtitleParts.add('Modalidade não definida');
    }
    final subtitle = subtitleParts.join(' · ');

    return KicksterCard(
      icon: Icons.shield_outlined,
      title: team.name,
      subtitle: subtitle,
      imageUrl: team.logoUrl,
      onTap: () {},
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isInactive)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: KicksterStatusChip(
                status: KicksterStatusChipType.failed,
                label: 'Inativo',
              ),
            ),
          KicksterMenuAnchor(
            width: 190,
            alignment: Alignment.topRight,
            trigger: Container(
              padding: const EdgeInsets.all(6),
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
              if (!isInactive)
                KicksterMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.block_outlined,
                          size: 18, color: AppColors.danger),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Desativar Equipe',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final ok = await showKicksterConfirm(
                      context: context,
                      title: 'Desativar Equipe',
                      content: 'Deseja desativar a equipe "${team.name}"?',
                      confirmLabel: 'Desativar',
                      danger: true,
                    );
                    if (ok == true) {
                      await vm.deactivateTeam(team.id);
                    }
                  },
                )
              else
                KicksterMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: AppColors.success),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Reativar Equipe',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await vm.reactivateTeam(team.id);
                  },
                ),
              KicksterMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Excluir Equipe',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  final ok = await showKicksterConfirm(
                    context: context,
                    title: 'Excluir Equipe',
                    content:
                        'Tem certeza que deseja excluir a equipe "${team.name}"? Esta ação não pode ser desfeita.',
                    confirmLabel: 'Excluir',
                    danger: true,
                  );
                  if (ok == true) {
                    await vm.deleteTeam(team.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateTeamModal(
    BuildContext context,
    InstitutionDetailViewModel vm,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final shortNameCtrl = TextEditingController();
    final logoUrlCtrl = TextEditingController();

    // Valores padrão para a seleção interativa
    Modality selectedModality = Modality.flag5x5;
    Gender selectedGender = Gender.male;
    AgeGroup selectedAgeGroup = AgeGroup.adult;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final storageService = ref.read(storageServiceProvider);

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sports_football_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nova Equipe Esportiva',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Identificação Básica: Nome e Sigla na mesma linha
                      const Text(
                        'Identificação da Equipe',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: KicksterInput(
                              label: 'Nome da Equipe *',
                              hintText: 'Ex.: Spartans Black, Spartans Feminino',
                              controller: nameCtrl,
                              maxLength: 100,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Informe o nome da equipe' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: KicksterInput(
                              label: 'Sigla',
                              hintText: 'SPA-BLK',
                              controller: shortNameCtrl,
                              maxLength: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. Logotipo da Equipe (Padrão KicksterImageUploader)
                      KicksterImageUploader(
                        label: 'Escudo / Logotipo da Equipe (Opcional)',
                        controller: logoUrlCtrl,
                        helperText: 'PNG, JPG ou WebP (máx. 5MB)',
                        uploadFunction: ({required bytes, required filename, onProgress}) =>
                            storageService.uploadTeamLogo(
                          bytes: bytes,
                          filename: filename,
                          onProgress: onProgress,
                        ),
                        onUploaded: (url) => setModalState(() {}),
                        onRemoved: () => setModalState(() {}),
                      ),
                      const SizedBox(height: 20),

                      // 3. Modalidade Esportiva Oficial (SelectableChip)
                      const Text(
                        'Modalidade Esportiva',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: Modality.values.map((m) {
                          final isSel = selectedModality == m;
                          return SelectableChip(
                            label: m.label,
                            selected: isSel,
                            onTap: () => setModalState(() => selectedModality = m),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // 4. Gênero (SelectableChip)
                      const Text(
                        'Gênero da Equipe',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: Gender.values.map((g) {
                          final isSel = selectedGender == g;
                          return SelectableChip(
                            label: g.label,
                            selected: isSel,
                            onTap: () => setModalState(() => selectedGender = g),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // 5. Categoria / Faixa Etária (SelectableChip)
                      const Text(
                        'Categoria / Faixa Etária',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AgeGroup.adult,
                          AgeGroup.sub20,
                          AgeGroup.sub17,
                          AgeGroup.sub15,
                          AgeGroup.master,
                          AgeGroup.open,
                        ].map((cat) {
                          final isSel = selectedAgeGroup == cat;
                          return SelectableChip(
                            label: cat.label,
                            selected: isSel,
                            onTap: () => setModalState(() => selectedAgeGroup = cat),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
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
                label: 'Cadastrar Equipe',
                icon: Icons.check,
                loading: vm.isSavingTeam,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final computedSportName =
                      '${selectedModality.label} ${selectedGender.label} (${selectedAgeGroup.label})';

                  final success = await vm.createTeam(
                    name: nameCtrl.text.trim(),
                    shortName: shortNameCtrl.text.trim().isEmpty
                        ? null
                        : shortNameCtrl.text.trim(),
                    sportName: computedSportName,
                    logoUrl: logoUrlCtrl.text.trim().isEmpty
                        ? null
                        : logoUrlCtrl.text.trim(),
                  );

                  if (success && dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

