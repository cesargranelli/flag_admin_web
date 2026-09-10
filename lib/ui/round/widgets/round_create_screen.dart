import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/round/view_models/round_create_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Formulário de criação de rodada.
class RoundCreateScreen extends ConsumerStatefulWidget {
  const RoundCreateScreen({super.key, this.competitionId});

  final String? competitionId;

  @override
  ConsumerState<RoundCreateScreen> createState() => _RoundCreateScreenState();
}

class _RoundCreateScreenState extends ConsumerState<RoundCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _number;
  late RoundCreateViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _number = TextEditingController();
    _viewModel = ref.read(roundCreateViewModelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.competitionId != null) {
        _viewModel.init(competitionId: widget.competitionId!);
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _viewModel.save();
    if (success && mounted) {
      context.pop();
    }
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o número';
    }
    final number = int.tryParse(value.trim());
    if (number == null) return 'Número inválido';
    if (number < 1) return 'O número deve ser maior ou igual a 1';
    _viewModel.setNumber(number);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp = ref.watch(effectiveCompetitionProvider);

    return AppScreen(
      title: 'Nova rodada',
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.rounds, route: '/rounds'),
        BreadcrumbItem('Nova'),
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
                    KicksterDropdown<String>(
                      label: 'Competição',
                      value: widget.competitionId ?? effectiveComp,
                      items: compItems
                          .map(
                            (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                          )
                          .toList(),
                      onChanged: (value) {
                        ref.read(selectedCompetitionProvider.notifier).state =
                            value;
                        // Note: would need to re-init viewmodel with new competition
                      },
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Selecione a competição'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    KicksterInput(
                      label: 'Número',
                      controller: _number,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 3,
                      hintText: 'Ex.: 1',
                      validator: _validateNumber,
                    ),
                    const SizedBox(height: 12),
                    KicksterInput(
                      label: 'Nome',
                      controller: _name,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) => _viewModel.setName(value),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Informe o nome'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    KicksterDropdown<RoundType>(
                      label: 'Tipo',
                      helperText:
                          'Fases: Regular, Playoffs, Wildcard, Semifinal, Final',
                      value: _viewModel.type,
                      items: RoundType.values
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                          )
                          .toList(),
                      onChanged: (value) => _viewModel.setType(value),
                      validator: (value) =>
                          value == null ? 'Selecione o tipo' : null,
                    ),
                    if (_viewModel.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _viewModel.errorMessage!,
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