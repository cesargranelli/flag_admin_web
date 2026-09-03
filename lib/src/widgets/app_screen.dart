import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Scaffold padrão das telas autenticadas do Admin Web.
///
/// - **Header pessoal**: avatar + nome + greeting + home icon (sticky)
/// - **Barra superior** (sticky, abaixo do header pessoal, apenas quando há
///   tela anterior na pilha): link "Voltar para {label}" à esquerda
///   (ícone + rótulo num único [InkWell]) e o **título da página
///   centralizado** no meio da barra.
/// - **Page Body** (scrollável, padding 24px): conteúdo da tela
class AppScreen extends ConsumerWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.backLabel,
    this.showUserHeader = true,
    this.scrollable = true,
  });

  final String title;
  final Widget body;

  /// Rótulo da página para a qual vamos voltar (a tela anterior na pilha).
  ///
  /// Telas que conhecem o nome real da página anterior o informam aqui.
  /// Quando `null`, [AppScreen] resolve o rótulo a partir do nome da rota
  /// anterior (fallback por módulo) ou usa 'Voltar'.
  final String? backLabel;

  final bool showUserHeader;
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPop = GoRouter.of(context).canPop();
    final currentPath =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    final isHome = currentPath == '/';
    final backLabel = _resolveBackLabel(context, this.backLabel);
    // Sem histórico: volta para a home. Sem rótulo: apenas "Voltar".
    final fallbackHome = !canPop && !isHome;
    final backText = fallbackHome
        ? 'Voltar para Início'
        : (backLabel == null ? 'Voltar' : 'Voltar para $backLabel');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header pessoal (sticky)
        if (showUserHeader) const _UserHeader(),
        // Barra superior (sticky — fixa acima do conteúdo scrollável):
        // link "Voltar para {label}" à esquerda + título centralizado.
        // Três colunas de largura igual (flex 1) — o título fica no centro
        // real da barra independente da largura do botão voltar.
        if (!isHome)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                // Coluna esquerda: botão voltar (conteúdo pode variar).
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      button: true,
                      label: backText,
                      child: InkWell(
                        onTap: () =>
                            canPop ? context.pop() : context.go('/'),
                        borderRadius: BorderRadius.circular(8),
                        hoverColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  backText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Coluna central: título realmente centralizado.
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                // Coluna direita: espaçamento de balanceamento (sem botão).
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        if (scrollable)
          // Page body (somente conteúdo, scrollável — nav fixa acima)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: body,
            ),
          )
        else
          // Page body em altura finita (Expanded): usado pelas telas de
          // listagem para permitir scroll raiz LIGHT (virtualização real via
          // altura finita nos grids/lists).
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: body,
            ),
          ),
      ],
    );
  }

  /// Resolve o rótulo da página anterior da barra superior.
  ///
  /// Prioridade:
  /// 1. [backLabel] informado pela tela (nome real conhecido).
  /// 2. Nome da rota anterior na pilha (fallback por módulo).
  /// 3. `null` — sem rótulo conhecido (o botão mostra apenas "Voltar").
  static String? _resolveBackLabel(BuildContext context, String? backLabel) {
    if (backLabel != null && backLabel.trim().isNotEmpty) return backLabel;

    final matches = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .matches;
    final prev = matches.length >= 2 ? matches[matches.length - 2] : null;
    return _previousRouteLabel(prev);
  }

  /// Mapeia o nome da rota anterior para um rótulo de módulo (fallback).
  /// Retorna `null` quando não há rótulo conhecido (ex.: rota desconhecida).
  static String? _previousRouteLabel(RouteMatchBase? prev) {
    final name =
        prev?.route is GoRoute ? (prev!.route as GoRoute).name : null;
    if (name == null) return null;
    return switch (name) {
      'teams' => 'Times',
      'teamDetail' => 'Time',
      'organizations' => 'Organizações',
      'organizationDetail' => 'Organização',
      'competitions' => 'Campeonatos',
      'competitionDetail' => 'Campeonato',
      'athletes' => 'Atletas',
      'athleteDetail' => 'Atleta',
      'venues' => 'Campos',
      'venueDetail' => 'Campo',
      'rounds' => 'Rodadas',
      'roundDetail' => 'Rodada',
      'games' => 'Jogos',
      'gameDetail' => 'Jogo',
      'rosters' => 'Elencos',
      'teamRoster' => 'Elenco',
      'users' => 'Usuários',
      'approvals' => 'Aprovações',
      'home' => 'Início',
      _ => null,
    };
  }
}

// ---------------------------------------------------------------------------
// User Header
// ---------------------------------------------------------------------------

/// Header pessoal com avatar, nome, greeting e bell icon.
/// Avatar clicável abre menu "Sair" para baixo.
class _UserHeader extends ConsumerWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((a) => a.state.user));
    final name = (user?.name ?? '').trim();
    final email = (user?.email ?? '').trim();
    final displayName = name.isNotEmpty ? name : email;
    final initials = _initials(name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar + nome (clicável → menu sair estilo KicksterDropdown)
          _UserMenuAnchor(
            displayName: displayName,
            email: email,
            initials: initials,
            onLogout: () => _confirmLogout(context, ref),
          ),

          const Spacer(),

          // Home icon
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(
              Icons.home_outlined,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final logout = await showKicksterConfirm(
      context: context,
      title: 'Sair',
      content: 'Deseja realmente encerrar a sessão?',
      confirmLabel: 'Sair',
    );
    if (logout == true) {
      ref.read(authControllerProvider.notifier).logout();
    }
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'[\s-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── User menu (estilo KicksterDropdown) ─────────────────────────────────────

/// Anchor do menu do usuário — avatar + nome + greeting.
/// Abre um [KicksterMenuAnchor] com o estilo do KicksterDropdown:
/// container único, raio 12, borda `line`, fundo `surface`,
/// itens de 48px com divisores internos.
class _UserMenuAnchor extends StatelessWidget {
  const _UserMenuAnchor({
    required this.displayName,
    required this.email,
    required this.initials,
    required this.onLogout,
  });

  final String displayName;
  final String email;
  final String initials;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final greeting = displayName.isNotEmpty ? 'Olá, bem-vindo!' : 'Bem-vindo!';

    return KicksterMenuAnchor(
      triggerLabel: 'Menu do usuário',
      trigger: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KicksterAvatar(name: displayName, size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      items: [
        // Cabeçalho do usuário (informativo, sem ação).
        KicksterMenuItem(
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: initials.isNotEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Sair (48px, ícone logout danger).
        KicksterMenuItem(
          onTap: onLogout,
          child: const Row(
            children: [
              Icon(
                Icons.logout_outlined,
                size: 18,
                color: AppColors.danger,
              ),
              SizedBox(width: 8),
              Text(
                'Sair',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
