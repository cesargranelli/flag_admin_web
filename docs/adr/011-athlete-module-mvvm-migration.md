# ADR-011: Migração do Módulo de Atletas para Nova Arquitetura Flutter MVVM

**Status:** Aceito  
**Data:** 2026-09-09  
**Autor:** Tech Lead (Flag Platform)  

---

## Contexto

O módulo de atletas e elencos no `flag_admin_web` utiliza uma arquitetura legada baseada em:
- API services diretos (`lib/src/api/services/`) sem Repository layer
- Providers Riverpod simples (`FutureProvider`) sem caching
- Screens `ConsumerWidget`/`ConsumerStatefulWidget` sem ViewModels dedicados
- Estrutura de pastas `lib/src/features/*/presentation/screens/`

Enquanto isso, os módulos de organizações, agremiações e competições já migraram para a nova arquitetura MVVM:
- Models em `lib/domain/models/` (Dart puro, fromJson/toJson)
- Services abstratos + implementação em `lib/data/services/`
- Repositories com cache em `lib/data/repositories/`
- ViewModels `ChangeNotifier` 1:1 com screens em `lib/ui/*/view_models/`
- Widgets `ConsumerStatefulWidget` em `lib/ui/*/widgets/`

**Problema:** Dois padrões arquiteturais coexistem, dificultando manutenção, onboarding e consistência do código.

## Decisão

Migrar o módulo de atletas e elencos para seguir o padrão MVVM já estabelecido nos módulos de agremiações e competições, alinhado às recomendações oficiais do Flutter:

- [Guide to App Architecture](https://docs.flutter.dev/app-architecture/guide)
- [Architecture Case Study](https://docs.flutter.dev/app-architecture/case-study)
- [Recommendations](https://docs.flutter.dev/app-architecture/recommendations)
- [Design Patterns](https://docs.flutter.dev/app-architecture/design-patterns)

### Referência Principal

O módulo de **agremiações (Institution)** servirá como referência canônica para todos os padrões:

```
lib/
  domain/models/           -- Modelos de domínio puros (fromJson/toJson, copyWith)
  data/
    services/              -- Serviço abstrato + implementação API (REST via ApiClient)
    repositories/          -- Camada de cache (TTL 30s, forceRefresh, invalidação em mutações)
  ui/
    <module>/
      view_models/         -- ChangeNotifier por tela (1:1 MVVM)
      widgets/             -- ConsumerStatefulWidget screens
        components/        -- Sub-widgets reutilizáveis
  src/
    providers/             -- Riverpod providers (Service -> Repository -> VM chain)
    router/                -- GoRouter com StatefulShellBranch por módulo
```

---

## Escopo da Migração

### 1. Domain Models

| Modelo Atual (legado) | Novo Modelo | Destino |
|----------------------|-------------|---------|
| `lib/src/domain/models/athlete.dart` | `lib/domain/models/athlete.dart` | Manter campos, ajustar imports |
| `lib/src/domain/models/roster_entry.dart` | `lib/domain/models/roster_entry.dart` | Manter campos, ajustar imports |
| `lib/src/domain/models/athlete_batch.dart` | `lib/domain/models/athlete_batch.dart` | Migrar |
| `lib/src/domain/models/roster_batch.dart` | `lib/domain/models/roster_batch.dart` | Migrar |
| `lib/src/domain/models/team_roster.dart` | Remover (legado) | Não migrar |
| `lib/src/domain/enums/athlete_position.dart` | `lib/src/domain/enums/athlete_position.dart` | Migrar |

**Padrão do modelo:**
```dart
class Athlete {
  final String id;
  final String name;
  // ... campos imutáveis

  const Athlete({required this.id, required this.name, ...});

  factory Athlete.fromJson(Map<String, dynamic> json) => Athlete(
    id: json['id'] as String,
    name: json['name'] as String,
    ...
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    ...
  };
}
```

### 2. Data Services

| Serviço Atual | Novo Serviço | Destino |
|--------------|-------------|---------|
| `lib/src/api/services/athlete_api.dart` | `lib/data/services/athlete_service.dart` | Abstract + ApiAthleteService |
| `lib/src/api/services/roster_api.dart` | `lib/data/services/roster_service.dart` | Abstract + ApiRosterService |

**Padrão do serviço:**
```dart
abstract class AthleteService {
  factory AthleteService(ApiClient client) = ApiAthleteService;
  Future<List<Athlete>> getAthletes();
  Future<Athlete> getAthlete(String id);
  Future<Athlete> createAthlete(Map<String, dynamic> body);
  Future<Athlete> updateAthlete(String id, Map<String, dynamic> body);
  Future<void> deleteAthlete(String id);
}

class ApiAthleteService implements AthleteService {
  final ApiClient _client;
  // implementação via _client.getOne(), _client.post(), etc.
}
```

### 3. Data Repositories

| Repositório | Destino |
|------------|---------|
| (não existe) | `lib/data/repositories/athlete_repository.dart` |
| (não existe) | `lib/data/repositories/roster_repository.dart` |

**Padrão do repository:**
```dart
class AthleteRepository {
  final AthleteService _service;
  
  // Cache em memória com TTL 30s
  List<Athlete>? _cache;
  DateTime? _lastFetch;
  static const Duration _cacheTtl = Duration(seconds: 30);

  Future<List<Athlete>> getAthletes({bool forceRefresh = false}) async {
    // lógica de cache...
  }
  
  void clearCache() { _cache = null; _lastFetch = null; }
}
```

### 4. UI ViewModels

| ViewModel | Tela | Destino |
|-----------|------|---------|
| (não existe) | Lista de Atletas | `lib/ui/athlete/view_models/athlete_view_model.dart` |
| (não existe) | Detalhe do Atleta | `lib/ui/athlete/view_models/athlete_detail_view_model.dart` |
| (não existe) | Cadastro de Atleta | `lib/ui/athlete/view_models/athlete_create_view_model.dart` |
| (não existe) | Edição de Atleta | `lib/ui/athlete/view_models/athlete_edit_view_model.dart` |
| `TeamRosterViewModel` (legado) | Elenco do Time | `lib/ui/athlete/view_models/roster_view_model.dart` |

**Padrão do ViewModel:**
```dart
class AthleteViewModel extends ChangeNotifier {
  final AthleteRepository _repository;
  
  List<Athlete> _athletes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  
  // Getters públicos...
  
  Future<void> load({bool forceRefresh = false}) async { ... }
  Future<bool> delete(String id) async { ... }
  void setSearchQuery(String query) { ... }
}
```

### 5. UI Widgets (Screens)

| Tela Atual | Nova Tela | Destino |
|-----------|----------|---------|
| `lib/src/features/athletes/presentation/screens/athletes_screen.dart` | Lista | `lib/ui/athlete/widgets/athlete_list_screen.dart` |
| `lib/src/features/athletes/presentation/screens/athlete_detail_screen.dart` | Detalhe | `lib/ui/athlete/widgets/athlete_detail_screen.dart` |
| `lib/src/features/athletes/presentation/screens/athlete_form_screen.dart` | Cadastro/Edição | `lib/ui/athlete/widgets/athlete_create_screen.dart` + `athlete_edit_screen.dart` |
| `lib/src/features/athletes/presentation/screens/athlete_import_screen.dart` | Importação | `lib/ui/athlete/widgets/athlete_import_screen.dart` |
| `lib/src/features/teams/presentation/screens/team_roster_screen.dart` | Elenco | `lib/ui/athlete/widgets/roster_screen.dart` |
| `lib/src/features/rosters/presentation/screens/roster_import_screen.dart` | Import Elenco | `lib/ui/athlete/widgets/roster_import_screen.dart` |

**Padrão da Screen:**
```dart
class AthleteListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AthleteListScreen> createState() => _AthleteListScreenState();
}

class _AthleteListScreenState extends ConsumerState<AthleteListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(athleteViewModelProvider).load(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(athleteViewModelProvider);
    return AppScreen(
      title: 'Atletas',
      body: AppLayout.content(child: ...),
    );
  }
}
```

### 6. Providers

Adicionar em `lib/src/providers/providers.dart`:

```dart
// Serviço de atletas (REST)
final athleteServiceProvider = Provider<AthleteService>(
  (ref) => ApiAthleteService(ref.watch(apiClientProvider)),
);

// Repositório de atletas (Cache TTL 30s)
final athleteRepositoryProvider = Provider<AthleteRepository>(
  (ref) => AthleteRepository(service: ref.watch(athleteServiceProvider)),
);

// ViewModel de listagem de atletas
final athleteViewModelProvider =
    ChangeNotifierProvider<AthleteViewModel>(
  (ref) => AthleteViewModel(repository: ref.watch(athleteRepositoryProvider)),
);

// ViewModel de detalhes de atleta (1:1 com AthleteDetailScreen)
final athleteDetailViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<AthleteDetailViewModel, String>(
  (ref, id) => AthleteDetailViewModel(
    repository: ref.watch(athleteRepositoryProvider),
    athleteId: id,
  ),
);

// ViewModel de cadastro de atleta
final athleteCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<AthleteCreateViewModel>(
  (ref) => AthleteCreateViewModel(
    repository: ref.watch(athleteRepositoryProvider),
  ),
);

// ViewModel de edição de atleta
final athleteEditViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<AthleteEditViewModel, String>(
  (ref, id) => AthleteEditViewModel(
    repository: ref.watch(athleteRepositoryProvider),
    athleteId: id,
  ),
);

// Serviço de elencos (REST)
final rosterServiceProvider = Provider<RosterService>(
  (ref) => ApiRosterService(ref.watch(apiClientProvider)),
);

// Repositório de elencos (Cache TTL 30s)
final rosterRepositoryProvider = Provider<RosterRepository>(
  (ref) => RosterRepository(service: ref.watch(rosterServiceProvider)),
);

// ViewModel de elenco
final rosterViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<RosterViewModel, String>(
  (ref, teamId) => RosterViewModel(
    repository: ref.watch(rosterRepositoryProvider),
    teamId: teamId,
  ),
);
```

### 7. Rotas

Atualizar `lib/src/router/app_router.dart` para usar as novas telas:

```dart
// Branch de Atletas
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/athletes',
      name: 'athletes',
      builder: (_, __) => const AthleteListScreen(),
      routes: [
        GoRoute(path: 'new', name: 'athleteNew',
            builder: (_, __) => const AthleteCreateScreen()),
        GoRoute(path: ':id', name: 'athleteDetail',
            builder: (_, state) => AthleteDetailScreen(
                id: state.pathParameters['id']!,
                athlete: state.extra as Athlete?)),
        GoRoute(path: ':id/edit', name: 'athleteEdit',
            builder: (_, state) => AthleteEditScreen(
                id: state.pathParameters['id']!,
                athlete: state.extra as Athlete?)),
        GoRoute(path: 'import', name: 'athleteImport',
            builder: (_, __) => const AthleteImportScreen()),
      ],
    ),
  ],
),
```

---

## Padrões de UI (Referência: Agremiações)

### Tela de Listagem
- `AppScreen` com título e breadcrumb
- `KicksterSearchField` para pesquisa
- `KicksterDropdown` para filtros (posição, status)
- Grid responsivo com `LayoutBuilder`
- Botão "Novo+" no header
- SWR (stale-while-revalidate) com periodic sync de 25s
- Pull-to-refresh

### Tela de Detalhe
- Hero card com nome, foto, informações principais
- Seções empilhadas com `KicksterSectionTitle`
- Botões de ação: Editar, Excluir
- Confirmação de exclusão via `showKicksterConfirm`

### Formulário de Cadastro
- `GlobalKey<FormState>` com validação
- Seções: Dados Pessoais, Posições, Informações Esportivas
- `KicksterInput` para campos de texto
- `KicksterDropdown` para seleções
- Botão de submit com loading state
- Navegação de volta após sucesso

### Formulário de Edição
- Mesma estrutura do cadastro, pré-populado
- `PopScope` com proteção de alterações não salvas

---

## Consequências

### Positivas
- ✅ Consistência arquitetural em todo o projeto
- ✅ Manutenibilidade: padrão único documentado
- ✅ Testabilidade: ViewModels isolados da UI
- ✅ Performance: cache TTL nos Repositories
- ✅ Experiência do desenvolvedor: mesmo padrão = menor curva de aprendizado

### Negativas
- ❌ Esforço inicial de migração (~21 arquivos afetados)
- ❌ Temporariamente dois padrões coexistindo (até migração completa)
- ❌ Necessidade de testes de regressão pós-migração

### Riscos
- ⚠️ Quebra de funcionalidade durante migração → mitigado por testes
- ⚠️ Import paths quebrados → mitigado por busca e substituição sistemática

---

## Critérios de Aceitação

- [ ] Todos os models migrados para `lib/domain/models/`
- [ ] Services abstratos + implementação em `lib/data/services/`
- [ ] Repositories com cache em `lib/data/repositories/`
- [ ] ViewModels `ChangeNotifier` 1:1 com cada tela
- [ ] Screens como `ConsumerStatefulWidget`
- [ ] Providers Riverpod com cadeia Service → Repository → VM
- [ ] Rotas atualizadas no `app_router.dart`
- [ ] Lint sem erros (`dart analyze`)
- [ ] Funcionalidade preservada (CRUD atletas, elencos, importação)
