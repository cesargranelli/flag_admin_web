# Relatório de Investigação Técnica: Conflito de Rotas, Reconciliação de Entidades e Contratos de Times no `flag_backend`

**Data:** 2026-09-07  
**Autor:** Architectural Explorer (`teamwork_preview_explorer`) — Milestone 1 (M1: Backend Domain & Rules Sync)  
**Repositório Alvo:** `C:\Projetos\America\flag_backend`  
**Arquivos Principais Auditados:**
- `src/main/java/br/com/flagplatform/organization/controller/OrganizationController.java`
- `src/main/java/br/com/flagplatform/organization/service/OrganizationService.java`
- `src/main/java/br/com/flagplatform/club/controller/ClubController.java`
- `src/main/java/br/com/flagplatform/club/service/ClubService.java`
- `src/main/java/br/com/flagplatform/institution/controller/InstitutionController.java`
- `src/main/java/br/com/flagplatform/institution/service/InstitutionService.java`
- `src/main/java/br/com/flagplatform/institution/mapper/InstitutionMapper.java`
- `src/main/java/br/com/flagplatform/team/controller/TeamController.java`
- `src/main/java/br/com/flagplatform/team/service/TeamService.java`
- `src/main/java/br/com/flagplatform/team/entity/TeamEntity.java`
- `src/main/java/br/com/flagplatform/team/entity/CompetitionTeamEntity.java`

---

## 1. Sumário Executivo

Esta investigação técnica analisou em detalhes a colisão de rotas no Spring MVC entre `OrganizationController` e `ClubController`, a coexistência e reconciliação das entidades `OrganizationEntity`, `InstitutionEntity` e `ClubEntity`, e a conformidade dos contratos de criação de times e inscrição em competições segundo a ADR-001.

### Principais Constatações:
1. **Colisão Crítica de Rotas no Spring MVC**:
   - `OrganizationController` (`@RequestMapping("/api/v1/organizations")`) registra `@PostMapping("/{id}/clubs")` e `@GetMapping("/{id}/clubs")`.
   - `ClubController` registra `@PostMapping("/api/v1/organizations/{organizationId}/clubs")` e `@GetMapping("/api/v1/organizations/{organizationId}/clubs")`.
   - Ambos os controladores mapeiam exatamente os mesmos verbos HTTP (`POST` e `GET`) para o mesmo padrão de URI (`/api/v1/organizations/{*}/clubs`), provocando `IllegalStateException: Ambiguous handler methods mapped` no Spring Framework em runtime e corrompendo a especificação OpenAPI.
2. **Divergência Semântica e Histórico Evolutivo**:
   - `OrganizationController` usa a rota para **associar** uma organização filha pré-existente (clube/universidade) a uma federação mãe (`child.parentId = parentId`), recebendo `AssociateClubRequest(organizationId)`.
   - `ClubController` usa a rota para **criar** uma nova entidade `ClubEntity` (`table: clubs`) vinculada à organização, recebendo `CreateClubRequest(name, shortName, ...)`.
   - Paralelamente, a ADR-009 introduziu `InstitutionEntity` (Agremiações com cores e filiação N:N via `institution_organizations`), que é o modelo ativamente consumido pelo `flag_admin_web` em `lib/ui/institutions`.
3. **Bug Mapeado em `InstitutionMapper` e Gap de Contrato**:
   - Em `InstitutionMapper.java` linha 15: `@Mapping(target = "organizations", ignore = true)` faz com que o campo `organizations` em `InstitutionResponse` seja **sempre serializado como `null`**, quebrando a listagem de organizações vinculadas à agremiação.
   - `InstitutionController.setOrganizations` espera `@RequestBody List<UUID> organizationIds`, enquanto o frontend `flag_admin_web` envia o objeto JSON `{'organizationIds': [...]}`.
4. **Contratos de Times (`TeamController`) Alinhados com a ADR-001**:
   - `POST /api/v1/organizations/{organizationId}/teams`: perfeitamente implementado, validando existência da organização, unicidade de nome do time e enriquecendo a resposta com `organizationName`.
   - `POST /api/v1/competitions/{competitionId}/teams/{teamId}`: perfeitamente implementado com corpo opcional `EnrollTeamRequest(divisionId)`, validação de compatibilidade entre divisão e competição, e bloqueio de inscrições duplicadas.

---

## 2. Diagnóstico da Colisão: `OrganizationController` vs `ClubController`

### 2.1 Mapeamento Comparativo das Rotas em Conflito

| Controlador | Anotação / Rota | Verbo HTTP | DTO de Entrada | DTO de Saída | Ação de Negócio Real |
|---|---|---|---|---|---|
| **`OrganizationController`** (linha 118) | `@RequestMapping("/api/v1/organizations")` + `@PostMapping("/{id}/clubs")` | `POST` | `AssociateClubRequest` (`UUID organizationId`) | `OrganizationResponse` | **Associa** organização filha existente (`parentId = id`). Não cria clube. |
| **`ClubController`** (linha 39) | `@PostMapping("/api/v1/organizations/{organizationId}/clubs")` | `POST` | `CreateClubRequest` (`name`, `shortName`, `sportName`, etc.) | `ClubResponse` | **Cria** novo `ClubEntity` na tabela `platform.clubs`. |
| **`OrganizationController`** (linha 106) | `@RequestMapping("/api/v1/organizations")` + `@GetMapping("/{id}/clubs")` | `GET` | Nenhum (path param `id`) | `List<OrganizationResponse>` | Lista organizações filhas (`parent_id = id` e `type IN (CLUB, UNIVERSITY)`). |
| **`ClubController`** (linha 52) | `@GetMapping("/api/v1/organizations/{organizationId}/clubs")` | `GET` | Paging (`page`, `size`) | `List<ClubResponse>` | Lista registros da tabela `platform.clubs` para o `organizationId`. |

### 2.2 Mecanismo da Falha no Spring MVC
O Spring `RequestMappingHandlerMapping` compila o índice de rotas usando a classe `PatternsRequestCondition`. Os nomes de variáveis de path (`{id}` vs `{organizationId}`) são ignorados na resolução; ambos mapeiam para o padrão regex `/api/v1/organizations/[^/]+/clubs`.

Como nenhum dos dois controladores define cabeçalhos `consumes`, `produces` ou parâmetros de query obrigatórios para desambiguação, o Spring detecta colisão estrita de manipuladores (ambiguity conflict). O resultado é:
```
java.lang.IllegalStateException: Ambiguous handler methods mapped for '/api/v1/organizations/123/clubs':
{public br.com.flagplatform.organization.dto.response.OrganizationResponse br.com.flagplatform.organization.controller.OrganizationController.associateClub(java.util.UUID,br.com.flagplatform.organization.dto.request.AssociateClubRequest),
 public br.com.flagplatform.club.dto.response.ClubResponse br.com.flagplatform.club.controller.ClubController.create(java.util.UUID,br.com.flagplatform.club.dto.request.CreateClubRequest)}
```

---

## 3. Análise e Reconciliação do Domínio: `Organization` vs `Institution` vs `Club`

### 3.1 As Três Entidades no Backend

1. **`OrganizationEntity` (`platform.organizations`)**:
   - Representa entidades jurídicas e institucionais (Federações, Ligas, Associações e originalmente Clubes).
   - Possui `organizationType` (`FEDERATION`, `LEAGUE`, `ASSOCIATION`, `UNIVERSITY`, `CLUB`, `OTHER`).
   - Possui auto-relacionamento `parent_id` (hierarquia 1:N legada).
   - Utilizada pelo `flag_admin_web` exclusivamente para Federações e Ligas (`lib/ui/organizations`).

2. **`InstitutionEntity` (`platform.institutions`) — ADR-009**:
   - Representa Agremiações Esportivas (Clubes e Universidades).
   - Atributos: `name`, `type` (`CLUB`, `UNIVERSITY`), `colors` (`text[]`), `status` (`ACTIVE`).
   - Relacionamento: **N:N** com `platform.organizations` via tabela de junção `platform.institution_organizations`.
   - **Justificativa no Domínio**: Uma agremiação esportiva (ex: "Corinthians Steamrollers", "São Paulo Spartans") disputa competições de múltiplos organizadores simultaneamente (Federação Estadual, Confederação Nacional, Liga Regional). Portanto, um vínculo 1:N rígido (`parent_id`) é inadequado para o esporte real.
   - Utilizada ativamente pelo `flag_admin_web` (`lib/ui/institutions`).

3. **`ClubEntity` (`platform.clubs`) — ADR-003 / V2**:
   - Tabela dedicada para clubes com vínculo 1:N (`organization_id`).
   - Atributos: `name`, `shortName`, `sportName`, `logoUrl`, `document`, `presidentName`, `status`.
   - Não é consumida pelo `flag_admin_web` (que adotou o modelo de Agremiações da ADR-009).

### 3.2 Problemas Identificados no Módulo de Instituições (`br.com.flagplatform.institution`)

#### Bug 1: `InstitutionMapper.java` ignora lista de organizações
- **Localização:** `src/main/java/br/com/flagplatform/institution/mapper/InstitutionMapper.java`, linha 15:
  ```java
  @Mapping(target = "colors", expression = "java(toList(entity.getColors()))")
  @Mapping(target = "organizations", ignore = true) // <-- BUG!
  InstitutionResponse toResponse(InstitutionEntity entity, List<java.util.UUID> organizations);
  ```
- **Consequência:** Na classe gerada `InstitutionMapperImpl.java`, a variável `organizations1` é inicializada como `null` e passada ao construtor de `InstitutionResponse`. As chamadas `GET /api/v1/institutions` e `GET /api/v1/institutions/{id}` **sempre retornam `organizations: null`**, impedindo o frontend de saber a quais federações a agremiação está vinculada!
- **Correção:** Substituir por `@Mapping(target = "organizations", source = "organizations")`.

#### Bug 2: Incompatibilidade no Payload de `setOrganizations`
- Em `InstitutionController.java` linha 55:
  ```java
  @PutMapping("/{id}/organizations")
  @PreAuthorize(SecurityExpressions.INSTITUTION_WRITE)
  public InstitutionResponse setOrganizations(@PathVariable UUID id, @RequestBody List<UUID> organizationIds)
  ```
- No frontend `flag_admin_web` (`lib/data/services/institution_service.dart`, linha 46):
  ```dart
  _client.put(
    '/api/v1/institutions/$id/organizations',
    {'organizationIds': orgIds}, // Envia objeto com chave organizationIds!
    (json) => json,
  );
  ```
- **Consequência:** Jackson lança `MismatchedInputException` ao tentar desserializar um objeto JSON `{ "organizationIds": [...] }` como `List<UUID>`.
- **Correção:** Criar DTO `public record SetOrganizationsRequest(List<UUID> organizationIds) {}` e aceitar tanto o objeto encapsulado quanto a lista direta, ou padronizar no DTO.

---

## 4. Auditoria dos Endpoints de Times (`TeamController.java`)

### 4.1 Criação de Time (`POST /api/v1/organizations/{organizationId}/teams`)
- **Implementação:** `TeamController.create` (linha 44) delegando para `TeamService.create` (linha 40).
- **Contrato:**
  - **Path:** `POST /api/v1/organizations/{organizationId}/teams`
  - **Corpo (`CreateTeamRequest`):**
    ```json
    {
      "name": "Spartans Flag",
      "shortName": "SPA",
      "sportName": "Flag Football",
      "logoUrl": "https://..."
    }
    ```
  - **Resposta (`TeamResponse`):**
    ```json
    {
      "id": "uuid",
      "organizationId": "uuid",
      "organizationName": "Nome da Organização",
      "name": "Spartans Flag",
      "shortName": "SPA",
      "sportName": "Flag Football",
      "logoUrl": "https://...",
      "status": "ACTIVE",
      "createdAt": "...",
      "updatedAt": "..."
    }
    ```
- **Validações Ativas:**
  1. `organizationLookup.assertExists(organizationId)`: lança `OrganizationNotFoundException` (404) se não existir.
  2. `teamRepository.existsByOrganizationIdAndNameIgnoreCase`: lança `DuplicateTeamNameException` (409) se houver time com mesmo nome na mesma organização.
  3. Preenchimento automático de `status = ACTIVE`.
  4. Resolução de `organizationName` via lookup.
- **Veredito:** **100% conforme com ADR-001 e PROJECT.md.**

### 4.2 Inscrição de Time em Competição (`POST /api/v1/competitions/{competitionId}/teams/{teamId}`)
- **Implementação:** `TeamController.enrollInCompetition` (linha 139) delegando para `TeamService.enrollInCompetition` (linha 102).
- **Contrato:**
  - **Path:** `POST /api/v1/competitions/{competitionId}/teams/{teamId}`
  - **Corpo (`EnrollTeamRequest`, opcional):**
    ```json
    {
      "divisionId": "uuid-da-divisao-opcional"
    }
    ```
  - **Resposta (`CompetitionTeamResponse`):**
    ```json
    {
      "id": "uuid",
      "competitionId": "uuid",
      "teamId": "uuid",
      "teamName": "Spartans Flag",
      "organizationId": "uuid",
      "organizationName": "Nome do Clube",
      "divisionId": "uuid-ou-null",
      "createdAt": "..."
    }
    ```
- **Validações Ativas:**
  1. `findEntityById(teamId)`: garante que o time existe (`TeamNotFoundException` - 404).
  2. Validação da Divisão (quando informada): verifica existência e se a divisão pertence à mesma competição (`DivisionCompetitionMismatchException` - 400).
  3. Validação de Unicidade: `competitionTeamRepository.existsByCompetitionIdAndTeamId`.
- **Oportunidades de Polimento Técnico:**
  - Atualmente, time já inscrito lança `IllegalArgumentException("Time já inscrito nesta competição")`. Deve lançar exceção de negócio com status HTTP 409 Conflict (`DuplicateTeamRegistrationException`).
  - Na remoção de inscrição (`removeFromCompetition`), inscrição inexistente lança `IllegalArgumentException`. Deve lançar exceção de negócio com status HTTP 404 Not Found.

---

## 5. Estratégia de Resolução Recomendada para o Worker (M1)

### Passo 1: Eliminar a Colisão de Rotas em `OrganizationController`
Como a ação de `OrganizationController.associateClub` é uma **filiação institucional entre organizações** (e não a criação de um clube), as rotas devem ser renomeadas para refletir sua real semântica REST:

Em `OrganizationController.java`:
1. **Substituir:**
   ```java
   // ANTES (COLISÃO COM ClubController):
   @PostMapping("/{id}/clubs")
   public OrganizationResponse associateClub(@PathVariable UUID id, @Valid @RequestBody AssociateClubRequest request)
   
   @GetMapping("/{id}/clubs")
   public List<OrganizationResponse> listClubs(@PathVariable UUID id)
   
   @DeleteMapping("/{id}/clubs/{clubId}")
   public void removeClub(@PathVariable UUID id, @PathVariable UUID clubId)
   ```
2. **POR:**
   ```java
   // DEPOIS (SEMÂNTICA REST CLARA E SEM COLISÃO):
   @Operation(summary = "Listar organizações filiadas (clubes/universidades)")
   @GetMapping("/{id}/affiliations")
   public List<OrganizationResponse> listAffiliatedClubs(@PathVariable UUID id) {
       return service.findClubs(id);
   }

   @Operation(summary = "Filiar organização (clube/universidade) a uma federação")
   @PostMapping("/{id}/affiliations")
   @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
   public OrganizationResponse associateClub(
           @PathVariable UUID id,
           @Valid @RequestBody AssociateClubRequest request) {
       return service.associateClub(id, request.organizationId());
   }

   @Operation(summary = "Remover filiação de organização")
   @DeleteMapping("/{id}/affiliations/{clubId}")
   @ResponseStatus(HttpStatus.NO_CONTENT)
   @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
   public void removeClub(
           @PathVariable UUID id,
           @PathVariable UUID clubId) {
       service.removeClubAssociation(id, clubId);
   }
   ```
   *(Nota de Compatibilidade: Se for desejado manter retrocompatibilidade transitória para remoção via path com 3 segmentos, pode-se manter `@DeleteMapping("/{id}/clubs/{clubId}")` como alias, pois ela não colide com rotas de 2 segmentos).*

Com isso, o `ClubController` passa a ser o proprietário exclusivo e canônico de:
- `POST /api/v1/organizations/{organizationId}/clubs`: Criação de clube sob organização.
- `GET /api/v1/organizations/{organizationId}/clubs`: Listagem de clubes sob organização.
- `GET /api/v1/clubs/{id}`: Detalhe do clube.
- `PUT /api/v1/clubs/{id}`: Atualização cadastral do clube.

### Passo 2: Corrigir `InstitutionMapper` e `InstitutionController`
1. Em `InstitutionMapper.java`:
   ```java
   @Mapping(target = "colors", expression = "java(toList(entity.getColors()))")
   @Mapping(target = "organizations", source = "organizations")
   InstitutionResponse toResponse(InstitutionEntity entity, List<java.util.UUID> organizations);
   ```
2. Em `dto/request/`:
   Criar `SetOrganizationsRequest.java`:
   ```java
   public record SetOrganizationsRequest(
           List<UUID> organizationIds
   ) {}
   ```
3. Em `InstitutionController.java`:
   Atualizar `setOrganizations` para aceitar `SetOrganizationsRequest`:
   ```java
   @PutMapping("/{id}/organizations")
   @PreAuthorize(SecurityExpressions.INSTITUTION_WRITE)
   public InstitutionResponse setOrganizations(
           @PathVariable UUID id,
           @RequestBody SetOrganizationsRequest req) {
       return service.setOrganizations(id, req.organizationIds());
   }
   ```

### Passo 3: Refinar Tratamento de Exceções em `TeamService.java`
1. No método `enrollInCompetition`:
   Substituir:
   ```java
   if (competitionTeamRepository.existsByCompetitionIdAndTeamId(competitionId, teamId)) {
       throw new IllegalArgumentException("Time já inscrito nesta competição");
   }
   ```
   Por:
   ```java
   if (competitionTeamRepository.existsByCompetitionIdAndTeamId(competitionId, teamId)) {
       throw new DuplicateTeamRegistrationException(team.getOrganizationId(), competitionId);
   }
   ```
2. No método `removeFromCompetition`:
   Substituir `IllegalArgumentException` por uma subclasse de `ApiException` com HTTP 404 (ex: `TeamNotFoundException` ou `EntityNotFoundException`).
