import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Detalhe de uma pessoa: apresenta os dados e oferece a edicao.
class PersonDetailScreen extends ConsumerStatefulWidget {
  const PersonDetailScreen({super.key, this.personId, this.person});

  final String? personId;
  final dynamic person;

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(personDetailViewModelProvider(widget.personId!));
      if (vm.person == null) vm.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final personId = widget.personId!;
    final vm = ref.watch(personDetailViewModelProvider(personId));

    final person = widget.person ?? vm.person;

    return AppScreen(
      title: person?.name ?? 'Pessoa',
      breadcrumb: [
        const BreadcrumbItem(AppStrings.home, route: '/'),
        const BreadcrumbItem('Pessoas', route: '/persons'),
        if (person?.name != null) BreadcrumbItem(person!.name),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          vm.isLoading && person == null
              ? const Expanded(
                  child: AppLoading(message: 'Carregando pessoa...'),
                )
              : vm.errorMessage != null && person == null
              ? Expanded(
                  child: AppErrorState(
                    message: 'Nao foi possivel carregar a pessoa',
                    onRetry: () => ref
                        .read(personDetailViewModelProvider(personId))
                        .load(forceRefresh: true),
                  ),
                )
              : Expanded(child: _buildDetail(context, person!)),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, dynamic person) {
    return AppLayout.detail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 1,
            shadowColor: AppColors.black.withValues(alpha: 0.08),
            color: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.line, width: 1),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
SizedBox(
                         width: 56,
                         height: 56,
                         child: KicksterAvatar(
                           name: person.name,
                           imageUrl: person.photoUrl,
                           size: 56,
                         ),
                       ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (person.roleLabel.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                person.roleLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  KicksterButton(
                    label: 'Editar dados',
                    icon: Icons.edit_outlined,
                    onPressed: () =>
                        context.go('/persons/${person.id}/edit', extra: person),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppInfoCard(
            children: [
              AppInfoRow(label: 'Nome', value: person.name),
              if (person.cpf != null && person.cpf!.isNotEmpty)
                AppInfoRow(label: 'CPF', value: person.cpf!),
              if (person.roleLabel.isNotEmpty)
                AppInfoRow(label: 'Funcao', value: person.roleLabel),
              if (person.gender != null && person.gender!.isNotEmpty)
                AppInfoRow(label: 'Genero', value: person.gender!),
              if (person.city != null && person.city!.isNotEmpty)
                AppInfoRow(label: 'Cidade', value: person.city!),
              if (person.status != null && person.status!.isNotEmpty)
                AppInfoRow(label: 'Status', value: person.status!),
              if (person.photoUrl != null && person.photoUrl!.isNotEmpty)
                AppInfoRow(label: 'URL da foto', value: person.photoUrl!),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Criado em ${formatBrDate(person.createdAt)}'
            '${person.updatedAt != null ? ' * Atualizado em ${formatBrDate(person.updatedAt)}' : ''}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
