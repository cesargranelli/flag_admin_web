import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/domain_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flag_admin_web/ui/approval/view_models/approval_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tela exclusiva do super usuário (ADMIN) para aprovar/rejeitar contas.
class ApprovalListScreen extends ConsumerStatefulWidget {
  const ApprovalListScreen({super.key});

  @override
  ConsumerState<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends ConsumerState<ApprovalListScreen> {
  final _searchController = TextEditingController();
  late ApprovalListViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ref.read(approvalListViewModelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.load(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch keeps the provider alive (required for autoDispose)
    ref.watch(approvalListViewModelProvider);
    return AppScreen(
      title: AppStrings.approvals,
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.approvals),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: ListenableBuilder(
              listenable: _vm,
              builder: (context, _) {
                if (_vm.isLoading) {
                  return const AppLoading(message: 'Carregando pendências...');
                }

                if (_vm.errorMessage != null) {
                  return AppErrorState(
                    message: _vm.errorMessage!,
                    onRetry: () => _vm.load(forceRefresh: true),
                  );
                }

                final items = _vm.filteredUsers;
                if (items.isEmpty) {
                  return const KicksterEmptyState(
                    message: 'Nenhuma conta aguardando aprovação',
                    description:
                        'Contas criadas por novos usuários aparecem aqui '
                            'para revisão.',
                    icon: Icons.verified_outlined,
                  );
                }
                return AppEntityListScreen<User>(
                  items: items,
                  cardBuilder: (user) => _approvalCard(context, user),
                  searchField: _searchController,
                  countLabel: 'contas pendentes',
                  countLabelSingular: 'conta pendente',
                  emptyMessage: 'Nenhuma conta encontrada',
                  mainAxisExtent: 96,
                  filter: (all, query) => query.isEmpty
                      ? all
                      : all
                            .where(
                              (u) =>
                                  u.name.toLowerCase().contains(query) ||
                                  u.email.toLowerCase().contains(query),
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

  Widget _approvalCard(BuildContext context, User user) {
    final roleLabel = user.role.label;
    final dateText = formatBrShortDateTime(user.createdAt);

    final subtitleParts = <String>[
      if (user.email.isNotEmpty) user.email,
      if (roleLabel.isNotEmpty) roleLabel,
      'Solicitado em $dateText',
    ].join(' · ');

    return KicksterCard(
      icon: Icons.person_outline,
      leading: KicksterAvatar(
        name: user.name,
        size: 40,
      ),
      title: user.name.isNotEmpty ? user.name : user.email,
      subtitle: subtitleParts,
      onTap: () {},
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusChip(user),
          const SizedBox(width: 8),
          KicksterMenuAnchor(
            triggerLabel: 'Ações de ${user.name}',
            alignment: Alignment.topRight,
            width: 230,
            trigger: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            items: [
              KicksterMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Homologar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
                onTap: () => _approve(context, user),
              ),
              KicksterMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top, size: 18, color: AppColors.warning),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Provisório', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
                onTap: () => _approveProvisionary(context, user),
              ),
              KicksterMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 18, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Trocar Perfil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
                onTap: () => _openRoleModal(context, user),
              ),
              KicksterMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Recusar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
                onTap: () => _reject(context, user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(User user) {
    return KicksterStatusChip(
      status: KicksterStatusChipType.pending,
      label: 'Pendente',
    );
  }

  Future<void> _approve(BuildContext context, User user) async {
    final confirmed = await showKicksterConfirm(
      context: context,
      title: 'Aprovar conta',
      content: 'Aprovar ${user.email}?\nO usuário terá acesso à plataforma.',
      confirmLabel: 'Aprovar',
      danger: false,
    );
    if (confirmed != true || !context.mounted) return;

    final success = await _vm.approve(user.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta aprovada com sucesso!')),
        );
        _vm.load(forceRefresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível aprovar.')),
        );
      }
    }
  }

  Future<void> _approveProvisionary(BuildContext context, User user) async {
    final confirmed = await showKicksterConfirm(
      context: context,
      title: 'Aprovar provisório',
      content: 'Aprovar ${user.email} de forma provisória?\nO usuário terá acesso limitado.',
      confirmLabel: 'Aprovar Provisório',
      danger: false,
    );
    if (confirmed != true || !context.mounted) return;

    final success = await _vm.approveProvisionary(user.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta aprovada provisoriamente!')),
        );
        _vm.load(forceRefresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível aprovar provisoriamente.')),
        );
      }
    }
  }

  void _openRoleModal(BuildContext context, User user) {
    String? selectedRole = user.role.toJson();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Trocar Perfil: ${user.name}'),
        content: StatefulBuilder(
          builder: (ctx, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Selecione o novo perfil:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                KicksterDropdown<String>(
                  label: 'Novo perfil',
                  value: selectedRole,
                  values: UserRole.availableRoles.map((r) => r.toJson()).toList(),
                  labels: UserRole.availableRoles.map((r) => r.label).toList(),
                  hint: 'Selecione o perfil',
                  onChanged: (value) {
                    selectedRole = value;
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: KicksterButton(
                        label: 'Cancelar',
                        variant: KicksterButtonVariant.outline,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KicksterButton(
                        label: 'Confirmar',
                        icon: Icons.check,
                        onPressed: selectedRole == null
                            ? null
                            : () {
                                Navigator.pop(context);
                                _vm.changeRole(user.id, selectedRole!);
                                _vm.load(forceRefresh: true);
                              },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _reject(BuildContext context, User user) async {
    final confirmed = await showKicksterConfirm(
      context: context,
      title: 'Rejeitar conta',
      content: 'Rejeitar ${user.email}?\nA conta será recusada.',
      confirmLabel: 'Rejeitar',
      danger: true,
    );
    if (confirmed != true || !context.mounted) return;

    final success = await _vm.reject(user.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta rejeitada com sucesso!')),
        );
        _vm.load(forceRefresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível rejeitar.')),
        );
      }
    }
  }
}
