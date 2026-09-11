import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/domain/models/person.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Gestao de pessoas: listagem com busca, filtro por role, cards e navegacao para detalhe.
class PersonListScreen extends ConsumerStatefulWidget {
  const PersonListScreen({super.key});

  @override
  ConsumerState<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends ConsumerState<PersonListScreen> {
  final _searchController = TextEditingController();

  static const _roleOptions = <String, String>{
    '': 'Todos',
    'athlete': 'Atleta',
    'coach': 'Tecnico',
    'manager': 'Gestor',
    'referee': 'Arbitro',
    'staff': 'Staff',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(personViewModelProvider).load(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(personViewModelProvider);

    return AppScreen(
      title: 'Pessoas',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem('Pessoas'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              KicksterButton(
                label: 'Importar',
                icon: Icons.upload_file,
                variant: KicksterButtonVariant.outline,
                onPressed: () => context.go('/persons/import'),
              ),
              const SizedBox(width: 8),
              KicksterButton(
                label: 'Novo',
                icon: Icons.add,
                onPressed: () => context.go('/persons/new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: vm.isLoading
                ? const AppLoading(message: 'Carregando pessoas...')
                : vm.errorMessage != null && vm.persons.isEmpty
                ? AppErrorState(
                    message: 'Nao foi possivel carregar as pessoas',
                    onRetry: () => ref
                        .read(personViewModelProvider)
                        .load(forceRefresh: true),
                  )
                : vm.filteredPersons.isEmpty
                ? KicksterEmptyState(
                    icon: Icons.person_outline,
                    message: vm.searchQuery.isEmpty
                        ? 'Nenhuma pessoa cadastrada'
                        : 'Nenhuma pessoa encontrada',
                    description: vm.searchQuery.isEmpty
                        ? 'Cadastre a primeira pessoa para comecar a usar.'
                        : 'Tente outro termo de busca.',
                    action: vm.searchQuery.isEmpty
                        ? KicksterButton(
                            label: 'Cadastrar pessoa',
                            icon: Icons.add,
                            onPressed: () => context.go('/persons/new'),
                          )
                        : null,
                  )
                : AppLayout.content(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: KicksterSearchField(
                                  controller: _searchController,
                                  onChanged: (value) => ref
                                      .read(personViewModelProvider)
                                      .setSearchQuery(value),
                                  hint: 'Buscar pessoa por nome',
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 180,
                                child: DropdownButtonFormField<String>(
                                  initialValue: vm.roleFilter ?? '',
                                  decoration: kicksterFieldDecoration(
                                    labelText: 'Funcao',
                                  ),
                                  items: _roleOptions.entries
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => ref
                                      .read(personViewModelProvider)
                                      .setRoleFilter(
                                        value?.isEmpty == true ? null : value,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${vm.filteredPersons.length} ${vm.filteredPersons.length == 1 ? 'pessoa' : 'pessoas'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: vm.filteredPersons.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final person = vm.filteredPersons[index];
                                return _personCard(context, person);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _personCard(BuildContext context, Person person) {
    final roleLabel = person.roleLabel;
    final subtitle = [if (roleLabel.isNotEmpty) roleLabel].join(' ');

    return KicksterCard(
      icon: Icons.person_outline,
      title: person.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      onTap: () => context.go('/persons/${person.id}', extra: person),
    );
  }
}
