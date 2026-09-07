# Relatório de Investigação Técnica: Finalização de Partidas e Recálculo de Classificação (M1)

**Data**: 2026-09-07  
**Autor**: Architectural Explorer (`teamwork_preview_explorer` - M1 Standings)  
**Repositório Investigado**: `C:\Projetos\America\flag_backend`  
**Repositórios Correlacionados**: `C:\Projetos\America\flag_referee_app`, `C:\Projetos\America\flag_public_app`, `C:\Projetos\America\flag_tester_e2e`  

---

## 1. Sumário Executivo

Esta investigação técnica analisou em detalhes a cadeia orientada a eventos para encerramento de partidas e recálculo da tabela de classificação em `flag_backend`, rastreando o endpoint `POST /api/v1/games/{id}/result`, a emissão do `GameResultRegisteredEvent` e a execução do `StandingService.recalculate`.

### Descoberta Central:
Identificamos um **desalinhamento crítico entre o backend e o aplicativo de arbitragem (`flag_referee_app`)**:
1. O backend implementou a arquitetura orientada a eventos (`GameResultRegisteredEvent` -> `StandingEventListener` -> `StandingService.recalculate`), mas condicionou essa cadeia exclusivamente ao endpoint `POST /api/v1/games/{id}/result`.
2. O aplicativo de arbitragem (`flag_referee_app`), ao finalizar uma partida, chama diretamente `PATCH /api/v1/games/{id}/status` com status `FINISHED`, pois seu `GameApi` sequer possui o método `registerResult`.
3. O método `GameService.updateStatus` aceita a transição `CONFERENCE -> FINISHED`, porém **não emite o evento `GameResultRegisteredEvent`**. Como consequência direta, **o recálculo de classificação nunca é executado na operação real**.
4. Pior ainda: uma vez em `FINISHED`, o jogo fica bloqueado contra chamadas a `registerResult` (que exige status `CONFERENCE`), e se o jogo foi finalizado com placar nulo, provoca um **`NullPointerException` no unboxing de inteiros em `StandingService`**, corrompendo o recálculo de toda a competição.

Apresentamos abaixo o rastreamento minucioso do fluxo, a análise das falhas e a estratégia de resolução robusta recomendada para os Workers de implementação.

---

## 2. Rastreamento Técnico do Fluxo Canônico

### 2.1 Ponto de Entrada HTTP: `POST /api/v1/games/{id}/result`
- **Arquivo**: `src/main/java/br/com/flagplatform/game/controller/GameController.java` (linhas 141–148)
- **Assinatura**:
  ```java
  @PostMapping("/api/v1/games/{id}/result")
  @ResponseStatus(HttpStatus.OK)
  @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
  public GameResponse registerResult(
          @Parameter(description = "Id do jogo") @PathVariable UUID id,
          @Valid @RequestBody RegisterGameResultRequest request) {
      return service.registerResult(id, request);
  }
  ```
- **Segurança**: Restrito a perfis `ADMIN` ou `MESA`.
- **Payload (`RegisterGameResultRequest`)**:
  - `homeScore` (Integer, `@NotNull`, `@Min(0)`)
  - `awayScore` (Integer, `@NotNull`, `@Min(0)`)

### 2.2 Execução no Domínio: `GameService.registerResult`
- **Arquivo**: `src/main/java/br/com/flagplatform/game/service/GameService.java` (linhas 231–247)
- **Anotação**: `@Transactional` (escopo de transação física Spring/JPA).
- **Passo a Passo**:
  1. `GameEntity entity = findEntityById(id);`
  2. **Validação de Estado**:
     ```java
     if (entity.getStatus() != GameStatus.CONFERENCE) {
         throw new GameNotInProgressException(entity.getStatus());
     }
     ```
     *Exige que a partida esteja no status prévio de conferência (`CONFERENCE`).*
  3. **Persistência do Placar e Status**:
     ```java
     entity.setHomeScore(request.homeScore());
     entity.setAwayScore(request.awayScore());
     entity.setStatus(GameStatus.FINISHED);
     GameEntity saved = repository.save(entity);
     ```
  4. **Resolução de Metadados**:
     ```java
     UUID competitionId = roundLookup.findCompetitionId(saved.getRoundId());
     ```
     *Recupera o `competitionId` correspondente à rodada (`roundId`) através da fronteira de módulo `RoundLookup`.*
  5. **Disparo do Evento de Domínio**:
     ```java
     applicationEventPublisher.publishEvent(new GameResultRegisteredEvent(saved.getId(), competitionId));
     ```
  6. **Retorno**: `return mapper.toResponse(saved);`
  7. **Commit da Transação**: O Spring executa o commit da transação principal no banco PostgreSQL (`platform.games`).

### 2.3 Captura do Evento: `StandingEventListener`
- **Arquivo**: `src/main/java/br/com/flagplatform/standing/service/StandingEventListener.java` (linhas 15–18)
- **Código**:
  ```java
  @Component
  @RequiredArgsConstructor
  public class StandingEventListener {

      private final StandingService standingService;

      @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
      public void onGameResultRegistered(GameResultRegisteredEvent event) {
          standingService.recalculate(event.competitionId());
      }
  }
  ```
- **Mecanismo Transacional**: A anotação `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)` garante que o listener só será executado se e somente se o commit da transação da partida for concluído com sucesso absoluto no banco de dados.

### 2.4 Motor de Recálculo: `StandingService.recalculate`
- **Arquivo**: `src/main/java/br/com/flagplatform/standing/service/StandingService.java` (linhas 42–61)
- **Anotação**: `@Transactional(propagation = Propagation.REQUIRES_NEW)`
  - *Justificativa técnica*: No estágio `AFTER_COMMIT`, a transação original foi comitada, mas a infraestrutura de sincronização do Spring ainda está no ciclo de finalização. Um `@Transactional` padrão (REQUIRED) reutilizaria esse contexto já encerrado e não realizaria o flush no banco. `REQUIRES_NEW` cria uma nova transação física de banco isolada para a tabela de classificação.
- **Passo a Passo do Recálculo**:
  1. Busca todos os times inscritos na competição em `platform.competition_team`:
     ```java
     List<UUID> teamIds = competitionTeamRepository.findAllByCompetitionIdOrderByCreatedAtAsc(competitionId)
             .stream().map(ct -> ct.getTeamId()).toList();
     ```
  2. Busca todas as partidas finalizadas (`status == 'FINISHED'`) pertencentes a todas as rodadas da competição:
     ```java
     List<FinishedGame> games = gameLookup.findFinishedByCompetitionId(competitionId);
     ```
  3. Limpa os registros de classificação existentes daquela competição:
     ```java
     repository.deleteAllByCompetitionId(competitionId);
     ```
  4. Para cada time inscrito, calcula as estatísticas agregadas (`played`, `wins`, `draws`, `losses`, `goalsFor`, `goalsAgainst` e `points = wins * 3 + draws * 1`).
  5. Salva todas as entidades em batch:
     ```java
     repository.saveAll(standings);
     ```
  6. Commit da nova transação.

---

## 3. Diagnóstico do Bypass e Modos de Falha

### 3.1 Por que o `flag_referee_app` ignora o `registerResult`?
1. Em `flag_referee_app/lib/src/api/services/game_api.dart`, existem métodos para `updateStatus`, `addScoreEvent`, `correctScore`, mas **não existe** nenhum método para chamar `POST /api/v1/games/{id}/result`.
2. No fluxo da tela de arbitragem (`flag_referee_app/lib/src/screens/game_operation_screen.dart` linhas 484–486):
   ```dart
   await ref.read(gameApiProvider).updateStatus(game.id, GameStatus.finished);
   ```
   Ao clicar em "Finalizar", o app consome `PATCH /api/v1/games/{id}/status` passando `FINISHED`.

### 3.2 Por que o backend aceita essa transição sem publicar o evento?
Em `GameService.java`:
```java
private boolean isValidTransition(GameStatus current, GameStatus requested) {
    return switch (current) {
        case SCHEDULED -> requested == GameStatus.OPEN || requested == GameStatus.CANCELLED;
        case OPEN -> requested == GameStatus.IN_PROGRESS || requested == GameStatus.CANCELLED;
        case IN_PROGRESS -> requested == GameStatus.CONFERENCE;
        case CONFERENCE -> requested == GameStatus.FINISHED; // <-- PERMITE!
        case FINISHED, CANCELLED -> false;
    };
}
```
E no método `updateStatus`:
```java
@Transactional
public GameResponse updateStatus(UUID id, GameStatus newStatus) {
    GameEntity entity = findEntityById(id);
    if (!isValidTransition(entity.getStatus(), newStatus)) {
        throw new InvalidGameStatusTransitionException(entity.getStatus(), newStatus);
    }

    entity.setStatus(newStatus);
    return mapper.toResponse(repository.save(entity)); // <-- SALVA SEM DISPARAR EVENTO!
}
```

### 3.3 A Tríplice Falha Arquitetural Resultante
1. **Falha 1 — Inconsistência Silenciosa**:
   `updateStatus` altera o status da partida para `FINISHED`, mas **nunca dispara `GameResultRegisteredEvent`**. A tabela `platform.standings` não é recalculada, deixando a classificação pública e do app vazia ou desatualizada.
2. **Falha 2 — Bloqueio Permanente de Registro (Lockout)**:
   Uma vez que o status foi alterado para `FINISHED`:
   - `registerResult` rejeita chamadas pois valida `if (entity.getStatus() != GameStatus.CONFERENCE)`.
   - `updateStatus` rejeita retroceder status pois `switch (FINISHED) -> false`.
   - O jogo fica permanentemente bloqueado sem que ninguém consiga forçar o registro do resultado ou o disparo do evento via API.
3. **Falha 3 — `NullPointerException` Letal no Recálculo**:
   - Em `GameEntity.java`: `homeScore` e `awayScore` são objetos `Integer` anuláveis.
   - Em `FinishedGame.java`:
     ```java
     public record FinishedGame(UUID homeTeamId, UUID awayTeamId, int homeScore, int awayScore) {}
     ```
     *Os campos são primitivos `int`.*
   - Em `GameService.java` (linha 258):
     ```java
     .map(game -> new FinishedGame(
             game.getHomeTeamId(),
             game.getAwayTeamId(),
             game.getHomeScore(), // <-- Se for null: unboxing para int causa NPE!
             game.getAwayScore()))
     ```
   - Se uma partida for finalizada via `updateStatus` sem gols lançados (ou com scores nulos), quando **qualquer outra partida** da competição for finalizada via `registerResult`, a chamada `gameLookup.findFinishedByCompetitionId` tentará converter todas as partidas `FINISHED` da competição, disparando `NullPointerException`.
   - **Resultado**: A transação do recálculo aborta com erro 500 e a tabela de classificação de toda a competição fica permanentemente travada.

---

## 4. Estratégia de Correção Recomendada (Fix Strategy)

Recomendamos uma abordagem de **defesa em profundidade** em 4 medidas sinérgicas:

### Medida 1: Resiliência e Auto-Disparo no `GameService.updateStatus` (Backend)
No arquivo `src/main/java/br/com/flagplatform/game/service/GameService.java`:
Quando a transição for para `GameStatus.FINISHED`:
1. Coalescer scores nulos para `0` (`if (entity.getHomeScore() == null) entity.setHomeScore(0);`).
2. Persistir a entidade com status `FINISHED`.
3. Disparar `applicationEventPublisher.publishEvent(new GameResultRegisteredEvent(saved.getId(), competitionId));`.

**Código Proposto para `GameService.updateStatus`**:
```java
@Transactional
public GameResponse updateStatus(UUID id, GameStatus newStatus) {
    GameEntity entity = findEntityById(id);
    if (!isValidTransition(entity.getStatus(), newStatus)) {
        throw new InvalidGameStatusTransitionException(entity.getStatus(), newStatus);
    }

    entity.setStatus(newStatus);
    if (newStatus == GameStatus.FINISHED) {
        if (entity.getHomeScore() == null) {
            entity.setHomeScore(0);
        }
        if (entity.getAwayScore() == null) {
            entity.setAwayScore(0);
        }
    }

    GameEntity saved = repository.save(entity);

    if (newStatus == GameStatus.FINISHED) {
        UUID competitionId = roundLookup.findCompetitionId(saved.getRoundId());
        applicationEventPublisher.publishEvent(new GameResultRegisteredEvent(saved.getId(), competitionId));
    }

    return mapper.toResponse(saved);
}
```
*Impacto*: Torna o backend imediatamente imune a clientes que utilizem `PATCH /status` para finalizar jogos. O recálculo ocorrerá com 100% de confiabilidade em qualquer caminho de encerramento.

### Medida 2: Proteção Anti-NPE em `GameService.findFinishedByCompetitionId` (Backend)
No arquivo `src/main/java/br/com/flagplatform/game/service/GameService.java`:
```java
@Override
public List<FinishedGame> findFinishedByCompetitionId(UUID competitionId) {
    List<UUID> roundIds = roundLookup.findRoundIdsByCompetitionId(competitionId);
    if (roundIds.isEmpty()) {
        return List.of();
    }

    return repository.findAllByRoundIdInAndStatus(roundIds, GameStatus.FINISHED)
            .stream()
            .map(game -> new FinishedGame(
                    game.getHomeTeamId(),
                    game.getAwayTeamId(),
                    game.getHomeScore() != null ? game.getHomeScore() : 0,
                    game.getAwayScore() != null ? game.getAwayScore() : 0))
            .toList();
}
```
*Impacto*: Elimina a vulnerabilidade de `NullPointerException` mesmo se existirem registros legados com placar nulo no banco de dados.

### Medida 3: Idempotência e Retificação em `GameService.registerResult` (Backend)
Permitir que `registerResult` aceite jogos em status `CONFERENCE` ou jogos já em `FINISHED`:
```java
if (entity.getStatus() != GameStatus.CONFERENCE && entity.getStatus() != GameStatus.FINISHED) {
    throw new GameNotInProgressException(entity.getStatus());
}
```
*Impacto*: Permite que a mesa ou administrador envie o placar oficial ou retifique um resultado mesmo após a partida ter entrado em `FINISHED`, republicando o evento e recalculando a classificação com o placar oficializado.

### Medida 4: Alinhamento Contratual no `flag_referee_app` (Milestone M5)
1. Em `flag_referee_app/lib/src/api/services/game_api.dart`, adicionar:
   ```dart
   Future<Game> registerResult(String id, {required int homeScore, required int awayScore}) =>
       _client.post(
         '/api/v1/games/$id/result',
         {'homeScore': homeScore, 'awayScore': awayScore},
         Game.fromJson,
       );
   ```
2. Em `flag_referee_app/lib/src/screens/game_operation_screen.dart`, atualizar `_confirmFinish`:
   ```dart
   await ref.read(gameApiProvider).registerResult(
     game.id,
     homeScore: game.homeScore ?? 0,
     awayScore: game.awayScore ?? 0,
   );
   ```
*Impacto*: Alinha a experiência e o contrato do app de arbitragem com as especificações da plataforma.

---

## 5. Diagnóstico de Compilação e Pré-requisitos do `flag_backend`

### 5.1 Especificações do Ambiente e `pom.xml`
- **JDK Target**: Java 25 (`<java.version>25</java.version>`).
- **Framework**: Spring Boot 4.1.0, Spring Modulith 2.1.0.
- **Processadores de Anotação**: Lombok 1.18.38, MapStruct 1.6.3, `lombok-mapstruct-binding 0.2.0`.
- **Wrappers Disponíveis**: `mvnw` e `mvnw.cmd` presentes na raiz do repositório `flag_backend`.
- **Estado de Build Existente**:
  - Diretório `target/classes` previamente gerado com sucesso.
  - Diretório `target/generated-sources/annotations` contendo os mappers MapStruct gerados (incluindo `GameMapperImpl.java`).
  - Plugin JOOQ (`jooq-codegen-maven`) **não está amarrado ao ciclo de compilação padrão** (`generate-sources`), o que significa que `./mvnw compile` executa puramente a compilação Java e geração MapStruct/Lombok sem exigir conexão ativa com banco de dados PostgreSQL.
- **Conformidade com Requisito R4**:
  - O repositório não possui `src/test/java`, em estrito cumprimento à diretriz de não manter testes unitários isolados nas aplicações, centralizando 100% da validação funcional no `flag_tester_e2e`.

### 5.2 Comando de Verificação Recomendado para o Worker
No diretório `C:\Projetos\America\flag_backend`:
```powershell
./mvnw.cmd clean compile
```
ou em ambientes bash:
```bash
./mvnw clean compile
```
Requer JDK 25 configurado no `JAVA_HOME` ou `PATH`.
