# Relatório de Exploração Arquitetural: flag_admin_web (ADR-001 Survey)

**Data:** 2026-09-07  
**Agente:** Architectural Codebase Explorer (`teamwork_preview_explorer`)  
**Repositório Alvo:** `C:\Projetos\America\flag_admin_web`  
**Baseline de Análise Estática:** `flutter analyze` limpo (0 issues). `flutter test` executando 53 testes unitários com 100% de aprovação.

---

## 1. Sumário Executivo

O `flag_admin_web` é uma aplicação Flutter Web voltada para a gestão de cadastros e operações esportivas pelo organizador da plataforma Flag Football.

O repositório encontra-se em um **estado de transição arquitetural**:
1. **Módulos de Referência (Conformes com ADR-001):** Os módulos de **Organizações** (`Organization`) e **Agremiações** (`Institution`) já foram migrados para a arquitetura alvo (ADR-001 / Guia Oficial de Arquitetura Flutter), adotando:
   - Camada de Domínio em `lib/domain/models/` com entidades imutáveis e serialização limpa;
   - Camada de Dados em `lib/data/services/` (interfaces e clientes REST) e `lib/data/repositories/` (Single Source of Truth, cache em memória e invalidação consistente);
   - Camada de Apresentação em `lib/ui/<module>/` com padrão MVVM estrito (relação 1:1 entre Views e ViewModels baseados em `ChangeNotifier`), desacoplamento total de chamadas HTTP, e uso sistemático do design system **Kickster**.
2. **Módulos Remanescentes (Legados / R1):** Os módulos de **Competições**, **Times**, **Atletas**, **Jogos**, **Elencos** e **Campos** ainda residem na estrutura antiga em `lib/src/features/` e `lib/src/api/services/`. Neles verificam-se violações da ADR-001:
   - Acesso direto de telas a `*Api` ou `FutureProvider` crus (`api.create()`, `api.update()`);
   - Falta de Repositories e ausência de ViewModels dedicados (lógica de estado e de validação dispersa em `ConsumerStatefulWidget`);
   - Modelos de domínio desatualizados em relação ao schema da ADR-001 (ex.: `Competition` sem o campo obrigatório `season`; `Team` ainda com FK `competitionId` direta em vez de pertencer a um clube/`organizationId`; `Roster` inexistente como entidade de agregação de temporada e `RosterEntry` apontando para `teamId` em vez de `rosterId`);
   - Uso de componentes legados de UI (`AppEmptyState`, `AppErrorState`, `SelectableCard`, `AppEntityListScreen`) em vez dos equivalentes Kickster.

A boa notícia técnica é que **o baseline compila e passa na análise estática com 0 erros e 0 warnings**, permitindo que a refatoração seja executada com passos seguros e incrementais.

---

## 2. Implementação de Referência (ADR-001 Pattern)

A análise aprofundada dos módulos `Organizações` e `Agremiações` revelou o contrato exato que deve nortear a refatoração dos demais módulos.

### 2.1 Camada de Domínio (`lib/domain/models/`)
- **Arquivos:**
  - `lib/domain/models/organization.dart`
  - `lib/domain/models/institution.dart`
- **Características:**
  - Classes puras Dart sem dependências de frameworks de UI ou de HTTP.
  - Imutabilidade através de campos `final` e construtores `const`.
  - Métodos `factory .fromJson(Map<String, dynamic> json)` tolerantes a dados legados/nulos (`_tryParseDate`, conversão segura de enums).
  - Método `toJson()` para serialização nos payloads de criação/edição.
  - Enums fortemente tipados no domínio (`InstitutionType` com `fromJson`, `toJson` e getter visual `label`).

### 2.2 Camada de Dados (`lib/data/`)

#### 2.2.1 Services (`lib/data/services/`)
- **Arquivos:**
  - `lib/data/services/organization_service.dart` (`OrganizationService` e `ApiOrganizationService`)
  - `lib/data/services/institution_service.dart` (`InstitutionService` e `ApiInstitutionService`)
- **Características:**
  - Interface abstrata definindo contratos REST de leitura e mutação:
    ```dart
    abstract class InstitutionService {
      factory InstitutionService(ApiClient client) = ApiInstitutionService;
      Future<List<Institution>> getInstitutions();
      Future<Institution> getInstitution(String id);
      Future<Institution> createInstitution(Map<String, dynamic> body);
      Future<Institution> updateInstitution(String id, Map<String, dynamic> body);
      Future<void> deleteInstitution(String id);
      Future<void> updateOrganizations(String id, List<String> orgIds);
    }
    ```
  - Implementação concreta `Api...Service` consome unicamente `ApiClient` (`_client.getList`, `_client.getOne`, `_client.post`, `_client.put`, `_client.delete`).
  - Totalmente desacoplada de estado e de cache.
  - Permite criação de fakes em `testing/fakes/` (`fake_organization_service.dart`, `fake_institution_service.dart`) viabilizando testes unitários rápidos e sem rede.

#### 2.2.2 Repositories (`lib/data/repositories/`)
- **Arquivos:**
  - `lib/data/repositories/organization_repository.dart`
  - `lib/data/repositories/institution_repository.dart`
- **Características:**
  - Atua como **Single Source of Truth** para a aplicação.
  - **Cache em memória:**
    ```dart
    class InstitutionRepository {
      final InstitutionService _service;
      List<Institution>? _cache;

      Future<List<Institution>> getInstitutions({bool forceRefresh = false}) async {
        if (!forceRefresh && _cache != null) return _cache!;
        final data = await _service.getInstitutions();
        _cache = List<Institution>.unmodifiable(data);
        return _cache!;
      }
      ...
      Future<Institution> createInstitution(...) async {
        final created = await _service.createInstitution(body);
        clearCache();
        return created;
      }
      void clearCache() => _cache = null;
    }
    ```
  - Mutações (`create`, `update`, `delete`, `reactivate`) chamam o serviço e imediatamente invalidam o cache (`clearCache()`).
  - Lookup rápido em cache por ID (`getInstitution(id)` / `getOrganization(id)`), buscando no serviço apenas se houver cache miss.

### 2.3 Camada de Apresentação (`lib/ui/<module>/`)

A camada de apresentação segue estritamente o padrão **MVVM com relação 1:1** entre Views e ViewModels.

#### 2.3.1 ViewModels (`lib/ui/<module>/view_models/`)
- **Arquivos Organizações:**
  - `organization_view_model.dart` (Listagem, filtros, busca, exclusão, reativação, seleção em lote)
  - `organization_detail_view_model.dart` (Carregamento e detalhe da entidade)
  - `organization_form_view_model.dart` (Criação e edição, estado de submissão)
  - `associate_clubs_view_model.dart` (Seleção e vinculação em lote)
- **Arquivos Agremiações:**
  - `institution_view_model.dart` (Listagem, filtros por tipo, busca, seleção)
  - `institution_detail_view_model.dart` (Detalhe da agremiação)
  - `institution_form_view_model.dart` (Criação, edição e associação N:N de organizações)
- **Padrão de Estado do ViewModel:**
  - Herdam de `ChangeNotifier`.
  - Expõem getters imutáveis para estado da UI:
    - `bool isLoading` / `bool isSubmitting`
    - `String? errorMessage`
    - `String? actionInProgressId` (evita bloquear a tela inteira quando uma ação pontual em uma linha está ocorrendo)
    - Coleções imutáveis (`List<T> get items`, `Set<String> get selectedIds`)
    - Filtros reativos (`searchQuery`, `typeFilter`, etc.)
  - Comandos assíncronos retornam `Future<bool>` ou `Future<void>` e atualizam o estado notificando via `notifyListeners()`.
  - Tratamento de exceções centralizado no ViewModel: captura erros, popula `errorMessage` e desliga flags de loading.

#### 2.3.2 Views / Widgets (`lib/ui/<module>/widgets/`)
- **Arquivos Organizações:**
  - `organizations_screen.dart`
  - `organization_detail_screen.dart`
  - `organization_form_screen.dart`
  - `associate_clubs_screen.dart`
  - `club_assignment_modal.dart`
- **Arquivos Agremiações:**
  - `institutions_screen.dart`
  - `institution_detail_screen.dart`
  - `institution_form_screen.dart`
  - `colors_picker_dialog.dart`
- **Interação View <-> ViewModel:**
  - As telas utilizam `ConsumerStatefulWidget` ou `ConsumerWidget` para obter o ViewModel registrado nos providers.
  - Reatividade declarativa com `ListenableBuilder(listenable: vm, builder: (context, _) => ...)` para redesenho apenas quando o ViewModel notifica.
  - A View **não conhece o Repository e não conhece o ApiClient**: ela apenas chama métodos do ViewModel (`vm.load()`, `vm.delete(id)`, `vm.save(...)`).
- **Adesão ao Design Kit Kickster:**
  - Banners e estados vazios: `KicksterEmptyState`.
  - Estados de erro e retentativa: `KicksterErrorState`.
  - Botões de ação e navegação: `KicksterButton` (variantes `primary`, `outline`, `danger`, `dangerOutline`, `text`, `success`).
  - Cards de listagem: `KicksterCard` (modo linha com ícone e badges ou modo tile).
  - Campos de seleção: `KicksterDropdown`.
  - Modais de confirmação: `KicksterDialog` e `showKicksterConfirm`.
  - Menus e navegação: `KicksterTopBar`, `KicksterBreadcrumb`, `KicksterAvatar`, `KicksterMenuAnchor`.

### 2.4 Injeção de Dependências e Providers (`lib/src/providers/providers.dart`)
O padrão de fios de injeção em Riverpod é:
1. `apiClientProvider` -> `Provider<ApiClient>`
2. `...ServiceProvider` -> `Provider<...Service>((ref) => ...Service(ref.watch(apiClientProvider)))`
3. `...RepositoryProvider` -> `Provider<...Repository>((ref) => ...Repository(service: ref.watch(...ServiceProvider)))`
4. `...ViewModelProvider` -> `ChangeNotifierProvider<...ViewModel>((ref) => ...ViewModel(repository: ref.watch(...RepositoryProvider)))`
5. ViewModels com parâmetro de ID (telas de detalhe):
   `ChangeNotifierProvider.autoDispose.family<...DetailViewModel, String>((ref, id) => ...DetailViewModel(repository: ref.watch(...RepositoryProvider), id: id))`
6. Providers de leitura simples (`FutureProvider<List<...>>`) leem exclusivamente a partir do Repository (`ref.watch(...RepositoryProvider).get...()`), nunca do `*Api` diretamente.

---

## 3. Módulos Alvo de Refatoração (R1) — Diagnóstico Detalhado

Abaixo está o inventário e a análise de lacunas dos 6 módulos que compõem o escopo do R1.

### 3.1 Módulo: Competições (`competitions`)
- **Localização atual:**
  - Telas: `lib/src/features/competitions/presentation/screens/` (`competitions_screen.dart`, `competition_create_screen.dart`, `competition_detail_screen.dart`, `competition_edit_screen.dart`, `groupings_screen.dart`)
  - Widgets: `lib/src/features/competitions/presentation/widgets/` (`competition_form_controller.dart`, `competition_form_sections.dart`, `conference_form_modal.dart`, `division_form_modal.dart`)
  - API: `lib/src/api/services/competition_api.dart`, `conference_api.dart`, `division_api.dart`
  - Modelo: `lib/src/domain/models/competition.dart`, `conference.dart`, `division.dart`
- **Problemas e Violações Identificadas:**
  1. **Modelo de Domínio Defasado (ADR-001):** O modelo `Competition` não possui o campo `season` (temporada, obrigatório na ADR-001).
  2. **Chamadas Diretas de API no Formulário:** Em `competition_create_screen.dart` e `competition_edit_screen.dart`, `CompetitionFormController` recebe closures chamando diretamente `ref.read(conferenceApiProvider).create(...)` e `ref.read(divisionApiProvider).create(...)`, além de chamar `ref.read(competitionApiProvider).create(...)` direto no submit da tela.
  3. **Ausência de Repository:** Não existe `CompetitionRepository`. As leituras são feitas por `competitionsProvider = FutureProvider(...)` chamando diretamente `CompetitionApi.listAll()`.
  4. **Ausência de ViewModels:** Não há `CompetitionViewModel`, `CompetitionDetailViewModel`, `CompetitionFormViewModel`, nem `GroupingViewModel`.
  5. **Componentes Legados:** Uso de `AppEntityListScreen<Competition>`, `AppEmptyState` e `AppErrorState`.
  6. **Diretórios Vazios:** Presença de pastas fantasmas (`lib/src/features/competitions/data/datasources/`, `repositories/`, `domain/entities/`, etc.).
- **Ações de Refatoração:**
  - Migrar `competition.dart` para `lib/domain/models/competition.dart`, adicionando o atributo obrigatório `final String season;`.
  - Criar `lib/data/services/competition_service.dart` (incorporando endpoints de season, conferences e divisions).
  - Criar `lib/data/repositories/competition_repository.dart` com cache e métodos de mutação.
  - Criar ViewModels em `lib/ui/competitions/view_models/` (`competition_view_model.dart`, `competition_detail_view_model.dart`, `competition_form_view_model.dart`, `groupings_view_model.dart`).
  - Migrar telas para `lib/ui/competitions/widgets/` substituindo componentes legados por Kickster.

### 3.2 Módulo: Times (`teams`)
- **Localização atual:**
  - Telas: `lib/src/features/teams/presentation/screens/` (`teams_screen.dart`, `team_create_screen.dart`, `team_detail_screen.dart`, `team_edit_screen.dart`, `team_roster_screen.dart`)
  - API: `lib/src/api/services/team_api.dart`
  - Modelo: `lib/src/domain/models/team.dart`
- **Problemas e Violações Identificadas:**
  1. **Conceito de Domínio Quebrado pela ADR-001:** O `team.dart` atual define `Team` como pertencente a uma competição (`required this.competitionId`, e `organizationId` nulo/opcional). Na ADR-001:
     - `Team` é sub-entidade de `Organization` (clube/universidade): `organizationId` é obrigatório e `competitionId` **não pertence** à entidade `Team`.
     - A inscrição de um time numa competição se dá via tabela/entidade associativa `CompetitionTeam` (`competition_id`, `team_id`, `division_id`).
  2. **Endpoints Obsoletos:** `TeamApi` usa `POST /api/v1/competitions/{compId}/clubs` (`associateClub`), enquanto a ADR-001 define `POST /api/v1/organizations/{orgId}/teams` (criação no clube) e `POST /api/v1/competitions/{compId}/teams/{teamId}` (inscrição).
  3. **Navegação e Telas:**
     - Falta a seção "Times" em `OrganizationDetailScreen` (requisito de alta prioridade da ADR-001).
     - `TeamsScreen` lista times de uma competição, mas deve consultar `CompetitionTeam` e permitir inscrição de times já existentes no clube.
     - `TeamDetailScreen` precisa exibir as informações do time e suas participações/elencos em competições.
  4. **Ausência de Repository e ViewModels:** Toda a gestão de times usa `FutureProvider.family` e `teamApiProvider` diretamente das telas.
- **Ações de Refatoração:**
  - Criar `lib/domain/models/team.dart` e `lib/domain/models/competition_team.dart` alinhados com a ADR-001.
  - Criar `lib/data/services/team_service.dart` e `lib/data/repositories/team_repository.dart`.
  - Implementar a aba/seção de times em `lib/ui/organizations/widgets/organization_detail_screen.dart`.
  - Criar `lib/ui/teams/view_models/` (`team_view_model.dart`, `team_form_view_model.dart`, `team_detail_view_model.dart`).
  - Migrar telas para `lib/ui/teams/widgets/`.

### 3.3 Módulo: Atletas (`athletes`)
- **Localização atual:**
  - Telas: `lib/src/features/athletes/presentation/screens/` (`athletes_screen.dart`, `athlete_detail_screen.dart`, `athlete_form_screen.dart`, `athlete_import_screen.dart`)
  - API: `lib/src/api/services/athlete_api.dart`
  - Modelo: `lib/src/domain/models/athlete.dart`, `athlete_batch.dart`
- **Problemas e Violações Identificadas:**
  1. `AthleteFormScreen` e `AthleteImportScreen` realizam chamadas diretas a `athleteApiProvider`.
  2. Ausência de `AthleteRepository` e cache em memória.
  3. Telas dependem de `AppEntityListScreen<Athlete>`, `AppEmptyState`, `AppErrorState`.
  4. Lógica de importação em lote (`athlete_import_screen.dart`) contém parsing de CSV/JSON e chamadas multipart/batch misturadas com estado local de widget.
- **Ações de Refatoração:**
  - Mover `athlete.dart` e `athlete_batch.dart` para `lib/domain/models/`.
  - Criar `lib/data/services/athlete_service.dart` e `lib/data/repositories/athlete_repository.dart`.
  - Criar ViewModels: `athlete_view_model.dart`, `athlete_detail_view_model.dart`, `athlete_form_view_model.dart`, `athlete_import_view_model.dart`.
  - Migrar telas para `lib/ui/athletes/widgets/` com suporte integral a Kickster.

### 3.4 Módulo: Elencos (`rosters`)
- **Localização atual:**
  - Telas: `lib/src/features/rosters/presentation/screens/` (`rosters_screen.dart`, `roster_import_screen.dart`) e `lib/src/features/teams/presentation/screens/team_roster_screen.dart`
  - API: `lib/src/api/services/roster_api.dart`
  - Modelos: `lib/src/domain/models/roster_entry.dart`, `roster_batch.dart`, `team_roster.dart`
- **Problemas e Violações Identificadas:**
  1. **Modelo `Roster` Inexistente:** Na implementação atual, só existe `RosterEntry` (que tem `teamId` direto) e `TeamRoster` (modelo legado com IDs inteiros). Falta a entidade de primeira classe `Roster` (`id`, `teamId`, `competitionId`, `name`, `season`, `status`).
  2. **`RosterEntry` Defasado:** `RosterEntry` aponta diretamente para `teamId` em vez de `rosterId`.
  3. **Endpoints Incompatíveis:** `roster_api.dart` chama `/api/v1/teams/{teamId}/roster`, sem considerar que o elenco é indexado por competição (`/api/v1/teams/{teamId}/roster?competitionId={compId}` ou endpoints próprios de `/rosters`).
  4. **Fragmentação de Telas:** A gestão de atletas em elencos está dividida entre `rosters_screen.dart` e `team_roster_screen.dart`, sem ViewModels e com componentes legados.
- **Ações de Refatoração:**
  - Criar `lib/domain/models/roster.dart` e atualizar `roster_entry.dart` para referenciar `rosterId`.
  - Remover `team_roster.dart` (legado obsoleto).
  - Criar `lib/data/services/roster_service.dart` e `lib/data/repositories/roster_repository.dart`.
  - Criar ViewModels em `lib/ui/rosters/view_models/` (`roster_view_model.dart`, `roster_import_view_model.dart`).
  - Migrar telas para `lib/ui/rosters/widgets/`.

### 3.5 Módulo: Jogos (`games`)
- **Localização atual:**
  - Telas: `lib/src/features/games/presentation/screens/` (`games_screen.dart`, `game_detail_screen.dart`, `game_form_screen.dart`, `game_import_screen.dart`)
  - API: `lib/src/api/services/game_api.dart`, `round_api.dart`, `standing_api.dart`
  - Modelos: `lib/src/domain/models/game.dart`, `game_batch.dart`, `score_event.dart`, `standing.dart`, `round.dart`
- **Problemas e Violações Identificadas:**
  1. Lógica densa de manipulação de placar, lances e status diretamente em `game_detail_screen.dart` e `games_screen.dart`.
  2. Chamadas diretas de mutação (`api.updateStatus`, `api.correctScore`, `api.addScoreEvent`) nos widgets.
  3. Dependência direta de `FutureProvider` e ausência de `GameRepository`.
- **Ações de Refatoração:**
  - Mover modelos para `lib/domain/models/`.
  - Criar `lib/data/services/game_service.dart` e `lib/data/repositories/game_repository.dart`.
  - Criar ViewModels: `games_view_model.dart`, `game_detail_view_model.dart`, `game_form_view_model.dart`, `game_import_view_model.dart`.
  - Migrar telas para `lib/ui/games/widgets/`.

### 3.6 Módulo: Campos (`venues`)
- **Localização atual:**
  - Telas: `lib/src/features/venues/presentation/screens/` (`venues_screen.dart`, `venue_detail_screen.dart`, `venue_form_screen.dart`)
  - API: `lib/src/api/services/venue_api.dart`
  - Modelo: `lib/src/domain/models/venue.dart`
- **Problemas e Violações Identificadas:**
  1. `VenueFormScreen` executa `ref.read(venueApiProvider).create(...)` / `update(...)` internamente no `ConsumerStatefulWidget`.
  2. `VenuesScreen` depende de `venuesProvider` bruto e `organizationsProvider` para mapear manualmente nomes de organizações em tempo de build.
  3. Ausência de `VenueRepository` e ViewModels.
  4. Telas utilizam `AppEntityListScreen<Venue>`, `AppEmptyState`, `AppErrorState`.
- **Ações de Refatoração:**
  - Mover `venue.dart` para `lib/domain/models/venue.dart`.
  - Criar `lib/data/services/venue_service.dart` e `lib/data/repositories/venue_repository.dart`.
  - Criar ViewModels em `lib/ui/venues/view_models/` (`venue_view_model.dart`, `venue_detail_view_model.dart`, `venue_form_view_model.dart`).
  - Migrar telas para `lib/ui/venues/widgets/`.

---

## 4. Componentes Legados e Padrões a Remover ou Substituir

### 4.1 Inventário de Widgets Legados em `lib/src/core/widgets/`

| Componente Legado | Status / Problema | Substituto Kickster Padronizado |
|---|---|---|
| `app_empty_state.dart` (`AppEmptyState`) | Não segue tipografia nem cores Kickster; botão básico não-Kickster | `kickster_empty_state.dart` (`KicksterEmptyState`) |
| `app_error_state.dart` (`AppErrorState`) | Usa `OutlinedButton` padrão e cores antigas | `kickster_error_state.dart` (`KicksterErrorState`) |
| `app_dropdown.dart` (`appDropdownItem`) | Helpers avulsos; dropdowns devem usar o componente completo | `kickster_dropdown.dart` (`KicksterDropdown<T>`) |
| `selectable_card.dart` (`SelectableCard`) | Card simples com seleção visual por `Container` primário | `kickster_card.dart` (`KicksterCard`) |
| `search_field.dart` | O arquivo define `KicksterSearchField`, mas tem nome genérico | Padronizar import ou renomear para `kickster_search_field.dart` |
| `app_entity_list_screen.dart` | Template genérico que acopla paginação/filtro de forma legada | Padronizar listagens consumindo `KicksterCard`, `KicksterSearchField` e `KicksterTable` diretamente nas views |

### 4.2 Pastas e Arquivos Fantasmas (Cruft) a Limpar
Existem subdiretórios totalmente vazios gerados por scaffolding antigo que devem ser eliminados:
- `lib/src/features/competitions/data/datasources/`
- `lib/src/features/competitions/data/repositories/`
- `lib/src/features/competitions/domain/entities/`
- `lib/src/features/competitions/domain/repositories/`
- `lib/src/features/competitions/presentation/providers/`
- `lib/src/features/teams/data/` (e subpastas vazias)
- `lib/src/features/teams/domain/` (e subpastas vazias)
- `lib/src/features/athletes/data/` e `domain/` vazias
- `lib/src/features/games/data/` e `domain/` vazias
- `lib/src/features/rosters/data/` e `domain/` vazias
- `lib/src/features/venues/data/` e `domain/` vazias
- `lib/src/features/seasons/` (módulo inteiro vazio)

### 4.3 Anti-Padrões a Erradicar
1. **Chamada de APIs REST em Telas:** Nenhuma tela deve importar `*Api` ou chamar métodos HTTP.
2. **Uso de `FutureProvider` cru para Listagens Editáveis:** Listagens sujeitas a criação, edição ou deleção devem ser governadas por `*ViewModel` que interage com `*Repository`.
3. **Estado mutável de formulários espalhado em `StatefulWidget`:** Toda lógica de validação complexa, submissão assíncrona e feedback de erro de formulário deve pertencer a um `*FormViewModel`.

---

## 5. Mapeamento de Dependências e Ordem de Refatoração Recomendada

### 5.1 Grafo de Dependências Entre Entidades
```
                     ┌──────────────────┐
                     │   Organization   │ ◄── (Pronto)
                     └────────┬─────────┘
                              │
               ┌──────────────┼──────────────┐
               │              │              │
               ▼              ▼              ▼
         ┌───────────┐  ┌───────────┐  ┌───────────┐
         │   Venue   │  │Competition│  │   Team    │
         │  (Campos) │  │  (Season) │  │  (Clube)  │
         └─────┬─────┘  └─────┬─────┘  └─────┬─────┘
               │              │              │
               │              │   ┌──────────┴──────────┐
               │              │   │                     │
               │              ▼   ▼                     ▼
               │      ┌───────────────┐           ┌───────────┐
               │      │CompetitionTeam│           │  Roster   │
               │      └───────┬───────┘           └─────┬─────┘
               │              │                         │
               │              ▼                         ▼
               │      ┌───────────────┐           ┌───────────┐
               │      │     Game      │           │RosterEntry│
               │      └───────────────┘           └─────┬─────┘
               │              ▲                         │
               └──────────────┘                         ▼
                                                  ┌───────────┐
                                                  │  Athlete  │ ◄── (Global)
                                                  └───────────┘
```

### 5.2 Sequência Recomendada de Refatoração

Com base nas dependências, a refatoração deve ser executada nas seguintes fases estruturadas:

#### **Fase 1: Módulo Campos (`venues`)**
- **Justificativa:** Entidade folha simples. Depende apenas de `Organization`. Baixo risco e estabelece o template limpo para as demais.
- **Entregas:**
  - `lib/domain/models/venue.dart`
  - `lib/data/services/venue_service.dart` + Fake Service para testes
  - `lib/data/repositories/venue_repository.dart`
  - `lib/ui/venues/view_models/` (`venue_view_model.dart`, `venue_detail_view_model.dart`, `venue_form_view_model.dart`)
  - `lib/ui/venues/widgets/` (`venues_screen.dart`, `venue_detail_screen.dart`, `venue_form_screen.dart`)
  - Atualização de rotas em `app_router.dart` e testes unitários correspondentes.

#### **Fase 2: Módulo Atletas (`athletes`)**
- **Justificativa:** Entidade global (atleta existe independentemente de competições).
- **Entregas:**
  - `lib/domain/models/athlete.dart` e `athlete_batch.dart`
  - `lib/data/services/athlete_service.dart`
  - `lib/data/repositories/athlete_repository.dart`
  - `lib/ui/athletes/view_models/` e `widgets/` (incluindo importação em lote desacoplada)
  - Rotas e testes unitários.

#### **Fase 3: Módulo Competições (`competitions`)**
- **Justificativa:** Base para inscrição de times e agendamento de jogos. Incorpora o campo `season` exigido pela ADR-001.
- **Entregas:**
  - Atualização do modelo com `season`, `conferencias` e `divisões`
  - `lib/data/services/competition_service.dart` e `lib/data/repositories/competition_repository.dart`
  - `lib/ui/competitions/view_models/` (`competition_view_model.dart`, `competition_detail_view_model.dart`, `competition_form_view_model.dart`, `groupings_view_model.dart`)
  - `lib/ui/competitions/widgets/`

#### **Fase 4: Módulo Times (`teams`)**
- **Justificativa:** Mudança estrutural central da ADR-001 (Time pertence a Clube, não à Competição; inscrição via `CompetitionTeam`).
- **Entregas:**
  - Modelos `Team` e `CompetitionTeam`
  - `lib/data/services/team_service.dart` e `lib/data/repositories/team_repository.dart`
  - Inclusão da aba/seção de gestão de Times dentro de `OrganizationDetailScreen`
  - `lib/ui/teams/view_models/` e `widgets/`
  - Reformulação de `AssociateClubsScreen` para inscrição de times existentes

#### **Fase 5: Módulo Elencos (`rosters`)**
- **Justificativa:** Amarra `Team` + `Competition` (season) + `Athlete`. Depende das Fases 2, 3 e 4.
- **Entregas:**
  - Modelos `Roster` e `RosterEntry` (vinculado a `rosterId`)
  - `lib/data/services/roster_service.dart` e `lib/data/repositories/roster_repository.dart`
  - `lib/ui/rosters/view_models/` e `widgets/`
  - Remoção de código obsoleto (`team_roster.dart`, `team_roster_screen.dart`)

#### **Fase 6: Módulo Jogos (`games`)**
- **Justificativa:** Depende de Competição, Rodada, Times inscritos e Campos.
- **Entregas:**
  - Modelos `Game`, `ScoreEvent`, etc.
  - `lib/data/services/game_service.dart` e `lib/data/repositories/game_repository.dart`
  - `lib/ui/games/view_models/` e `widgets/` (gestão de placar e lances via ViewModel)

#### **Fase 7: Limpeza Geral e Consolidação de Infraestrutura**
- **Justificativa:** Repositório 100% limpo, sem resíduos legados.
- **Entregas:**
  - Remoção de `lib/src/features/` e pastas vazias remanescentes
  - Eliminação de `*Api` legados em `lib/src/api/services/`
  - Depreciação ou substituição final de `app_empty_state.dart`, `app_error_state.dart`
  - Limpeza e simplificação de `lib/src/providers/providers.dart`
  - Garantia de 0 warnings no `flutter analyze` e cobertura de testes.

---

## 6. Estratégia de Validação

De acordo com o requisito R4 (`ORIGINAL_REQUEST.md`):
1. **Análise Estática Local:** A cada fase, rodar `flutter analyze` garantindo 0 warnings e 0 errors.
2. **Testes Unitários de Regra:** Manter e expandir testes unitários de Repositories e ViewModels em `test/data/` e `test/ui/` utilizando fakes (conforme o padrão estabelecido para Organizações e Agremiações).
3. **Validação Funcional Externa:** Nenhuma suíte de integração complexa ou E2E deve ser criada dentro do `flag_admin_web`. Toda validação de ponta a ponta é de responsabilidade do projeto `flag_tester_e2e` (Playwright/TypeScript).

---
*Relatório concluído com sucesso por Architectural Codebase Explorer.*
