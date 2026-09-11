/// Textos centralizados da UI (pt-BR default).
///
/// Ponto único para externalizar strings e permitir localização futura
/// (arb/intl). Novas telas devem usar estas chaves em vez de texto hardcoded.
abstract final class AppStrings {
  // Comum
  static const save = 'Salvar';
  static const cancel = 'Cancelar';
  static const back = 'Voltar';
  static const continueNext = 'Continuar';
  static const retry = 'Tentar novamente';
  static const loading = 'Carregando...';

  // Autenticação
  static const loginTitle = 'Flag Admin Web';
  static const loginSubtitle = 'Acesso do organizador';
  static const loginEmail = 'E-mail';
  static const loginPassword = 'Senha';
  static const loginSubmit = 'Entrar';
  static const loginInvalidEmail = 'E-mail inválido';
  static const loginRequiredEmail = 'Informe o e-mail';
  static const loginRequiredPassword = 'Informe a senha';
  static const loginConnectionError = 'Não foi possível conectar ao servidor.';

  // Home / navegação
  static const appBarTitle = 'Admin Web';
  static const welcome = 'Bem-vindo';
  static const hello = 'Olá';
  static const quickActions = 'Ações rápidas';
  static const modules = 'Módulos';
  static const newCompetition = 'Nova competição';
  static const newGame = 'Novo jogo';
  static const importPersons = 'Importar pessoas';
  static const newOrganization = 'Nova organizacao';
  static const logout = 'Sair';
  static const homeHint = 'Selecione uma opcao para gerenciar os cadastros.';
  static const organizations = 'Organizacoes';
  static const institutions = 'Agremiacoes';
  static const competitions = 'Competicoes';
  static const approvals = 'Aprovacoes';
  static const categories = 'Categorias';
  static const venues = 'Locais';
  static const teams = 'Times';
  static const rounds = 'Rodadas';
  static const games = 'Jogos';
  static const persons = 'Pessoas';
  static const athletes = 'Atletas'; // Alias mantido para retrocompatibilidade
  static const rosters = 'Elencos';
  static const users = 'Usuarios';
  static const groupings = 'Conferencias e divisoes';
  static const associateClubs = 'Associar clubes';
  static const home = 'Inicio';
  static const notFoundTitle = 'Pagina nao encontrada';
  static const notFoundMessage = 'O link que voce acessou nao existe.';
  static const backToHome = 'Voltar ao inicio';
}
