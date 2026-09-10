import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/approval/view_models/approval_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tela exclusiva do super usuário (ADMIN) para aprovar/rejeitar contas.
class ApprovalListScreen extends ConsumerStatefulWidget {
  const ApprovalListScreen({super.key});

  @override
  ConsumerState<ApprovalListScreen> createState() =>
      _ApprovalListScreenState();
}

class _ApprovalListScreenState extends ConsumerState<ApprovalListScreen> {
  final _searchController = TextEditingController();
  late ApprovalListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(approvalListViewModelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.load(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              listenable: _viewModel,
              builder: (context, _) {
                if (_viewModel.isLoading) {
                  return const AppLoading(message: 'Carregando pendências...');
                }

                if (_viewModel.errorMessage != null) {
                  return AppErrorState(
                    message: _viewModel.errorMessage!,
                    onRetry: () => _viewModel.load(forceRefresh: true),
                  );
                }

                final items = _viewModel.filteredUsers;
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
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
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
                    label: 'Rejeitar',
                    icon: Icons.close,
                    variant: KicksterButtonVariant.danger,
                    onPressed: () => _reject(context, user),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KicksterButton(
                    label: 'Aprovar',
                    icon: Icons.check,
                    variant: KicksterButtonVariant.success,
                    onPressed: () => _approve(context, user),
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
    final success = await _viewModel.approve(user.id);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível aprovar.')),
      );
    }
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

    final success = await _viewModel.reject(user.id);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível rejeitar.')),
      );
    }
  }
}