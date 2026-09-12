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
                  cardBuilder: (user) => _approvalCard(context, ref, user),
                  searchField: _searchController,
                  countLabel: 'contas pendentes',
                  countLabelSingular: 'conta pendente',
                  emptyMessage: 'Nenhuma conta encontrada',
                  mainAxisExtent: 200,
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

  Widget _approvalCard(BuildContext context, WidgetRef ref, User user) {
    final roleLabel = user.role.label;
    final dateText = formatBrShortDateTime(user.createdAt);

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.name.isNotEmpty)
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${roleLabel.isNotEmpty ? '$roleLabel · ' : ''}Solicitado em $dateText',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: KicksterButton(
                    label: 'Aprovar',
                    icon: Icons.check,
                    variant: KicksterButtonVariant.success,
                    onPressed: () => _approve(context, user),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KicksterButton(
                    label: 'Provisório',
                    icon: Icons.hourglass_top,
                    variant: KicksterButtonVariant.outline,
                    onPressed: () => _approveProvisionary(context, user),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KicksterButton(
                    label: 'Trocar',
                    icon: Icons.swap_horiz,
                    variant: KicksterButtonVariant.text,
                    onPressed: () => _openRoleModal(context, user),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KicksterButton(
                    label: 'Recusar',
                    icon: Icons.close,
                    variant: KicksterButtonVariant.danger,
                    onPressed: () => _reject(context, user),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
