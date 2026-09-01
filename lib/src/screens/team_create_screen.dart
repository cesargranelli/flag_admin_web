import 'package:flag_admin_web/src/api/flag_api.dart';
import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Formulário de criação de time dentro de uma organização (clube).
///
/// O [organizationId] é obrigatório e deve ser passado via rota.
/// O formulário permite definir nome (obrigatório), sigla e URL do logo.
class TeamCreateScreen extends ConsumerStatefulWidget {
  const TeamCreateScreen({super.key, required this.organizationId});

  /// ID da organização (clube) ao qual o time pertence.
  final String organizationId;

  @override
  ConsumerState<TeamCreateScreen> createState() => _TeamCreateScreenState();
}

class _TeamCreateScreenState extends ConsumerState<TeamCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _shortName;
  late final TextEditingController _logoUrl;
  bool _submitting = false;
  String? _errorMessage;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(teamApiProvider);
      await api.create(
        widget.organizationId,
        name: _name.text.trim(),
        shortName: _shortName.text.trim().isEmpty
            ? null
            : _shortName.text.trim(),
        logoUrl: _logoUrl.text.trim().isEmpty
            ? null
            : _logoUrl.text.trim(),
      );
      ref.invalidate(clubTeamsProvider(widget.organizationId));
      if (mounted) {
        // Volta para o detalhe do clube (o "Novo time" usa `go`, que
        // substituiu a rota do clube — `pop()` não retornaria a ele).
        context.go('/organizations/${widget.organizationId}');
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
    return AppScreen(
      title: 'Novo time',
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
