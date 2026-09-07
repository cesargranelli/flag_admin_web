import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/domain/models/auth_user.dart';

/// Regras de permissão de edição sobre uma competição (issue #261).
///
/// O backend (PR #262) já bloqueia update/delete via ownership guard
/// (ssertManagedBy); aqui a mesma regra é espelhada apenas para
/// ocultar as ações que o usuário não pode executar (UX), mantendo o
/// backend como fonte da verdade.

/// true quando [user] tem papel ADMIN da plataforma.
bool isAdminUser(User? user) => user?.role == UserRole.admin;

/// true quando [user] (AuthUser) tem papel ADMIN da plataforma.
bool isAuthUserAdmin(AuthUser? user) => user?.role == UserRole.admin;

/// Usuário logado pode gerenciar [competition]?
///
/// Regra: ADMIN sempre pode; o criador pode editar suas competições;
/// registros legados sem createdBy ficam restritos ao ADMIN.
/// Sem usuário logado ou sem a competição resolvida, apenas ADMIN edita.
bool canEditCompetition(User? user, Competition? competition) {
  if (isAdminUser(user)) return true;
  if (user == null || competition == null) return false;
  final createdBy = competition.createdBy;
  if (createdBy == null || createdBy.isEmpty) return false;
  return createdBy == user.id;
}

/// Sobrecarga para [AuthUser].
bool canAuthUserEditCompetition(AuthUser? user, Competition? competition) {
  if (isAuthUserAdmin(user)) return true;
  if (user == null || competition == null) return false;
  final createdBy = competition.createdBy;
  if (createdBy == null || createdBy.isEmpty) return false;
  return createdBy == user.id;
}
