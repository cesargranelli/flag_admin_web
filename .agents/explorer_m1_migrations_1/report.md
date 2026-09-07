# Relatório Técnico de Investigação: Schemas de Banco de Dados e Migrações Flyway no `flag_backend`

**Data:** 2026-09-07  
**Autor:** Architectural Explorer (`teamwork_preview_explorer`) — Milestone 1 (M1: Backend Domain & Rules Sync)  
**Repositório Alvo:** `C:\Projetos\America\flag_backend`  
**Escopo:** Schema PostgreSQL (`platform`), Flyway migrations, entidades JPA (Hibernate 6 / Spring Boot 4.1.0) e sincronização do modelo de domínio.

---

## 1. Sumário Executivo

Esta investigação técnica realizou uma auditoria completa e minuciosa da camada de persistência do `flag_backend`, comparando o script base de migração `V1__MomentZero.sql` contra todas as 19 entidades JPA mapeadas, repositórios de dados diretos (JDBC) e as migrações já existentes no projeto.

### Descoberta Crítica: O "Ponto Cego" do Levantamento Inicial
O relatório preliminar da plataforma (`platform_report.md`) indicava que tabelas cruciais como `platform.clubs`, `platform.institutions`, `platform.institution_organizations` e a coluna `team.club_id` não existiam nas migrações do Flyway, dependendo exclusivamente da criação dinâmica do Hibernate (`spring.jpa.hibernate.ddl-auto: update`).

**A realidade do código-fonte:**
As migrações dessas estruturas **já foram criadas**, porém não em formato `.sql` em `src/main/resources/db/migration/`, mas sim como **classes Java de migração Flyway baseadas em jOOQ DSL** em `src/main/java/db/migration/` (em estrita conformidade com o **ADR-007: Migrações Flyway em Java com JOOQ** e **ADR-009**):
- `V2__CreateClubsAndRefactorTeams.java`: Cria `platform.clubs`, adiciona `team.club_id` e FK `fk_team_club`.
- `V3__MakeUsersPasswordHashNullable.java`: Torna `password_hash` anulável em `platform.users` (ADR-008).
- `V4__RemovePasswordHashAndResetTokens.java`: Remove `password_reset_tokens` e a coluna `password_hash` (transição para Firebase Auth / ADR-004/ADR-008).
- `V5__CreateInstitutionsAndInstitutionOrganizations.java`: Cria `platform.institutions`, `platform.institution_organizations` e o índice `idx_institution_organizations_organization_id` (ADR-009).

Todas as classes já constam compiladas em `target/classes/db/migration/`.

### Risco Crítico de Conflito de Versão no Flyway
Se um Worker simplesmente criar um arquivo `V2__Refactor_Schema.sql` em `src/main/resources/db/migration/`, o Flyway encontrará **duas migrações com versão 2** no mesmo classpath (`V2__Refactor_Schema.sql` e `V2__CreateClubsAndRefactorTeams.class`), provocando falha fatal no boot da aplicação:
```
org.flywaydb.core.api.FlywayException: Found more than one migration with version 2
```
Portanto, a estratégia de correção deve endereçar explicitamente se o projeto consolidará tudo em arquivos SQL (removendo as classes Java duplicadas) ou se adicionará uma nova versão sequencial (`V6`). Este relatório detalha a especificação SQL completa para ambas as abordagens.

---

## 2. Matriz Comparativa: `V1__MomentZero.sql` vs Entidades JPA

Auditoria detalhada campo a campo entre o schema inicial V1 e as entidades JPA atuais:

| Tabela PostgreSQL | Entidade JPA / Repositório | Status em V1 | Status Atual em Java / Migrações | Gaps / Divergências Identificadas |
|---|---|---|---|---|
| `platform.institutions` | `InstitutionEntity.java` | ❌ Inexistente | ✅ Criada em `V5` (Java/jOOQ) | Ausente no V1 SQL. `V5` não definiu `DEFAULT gen_random_uuid()` no campo `id` e omitiu as colunas de auditoria `created_by` e `updated_by` (presentes em `BaseEntity`). |
| `platform.institution_organizations` | `InstitutionOrganizationRepository.java` | ❌ Inexistente | ✅ Criada em `V5` (Java/jOOQ) | Ausente no V1 SQL. Tabela associativa N:N com PK composta `(institution_id, organization_id)`, FKs com `ON DELETE CASCADE` para ambas as tabelas e índice em `organization_id`. |
| `platform.clubs` | `ClubEntity.java` | ❌ Inexistente | ✅ Criada em `V2` (Java/jOOQ) | Ausente no V1 SQL. Contém FK para `platform.organizations(id)`. |
| `platform.team` | `TeamEntity.java` | ⚠️ Parcial (sem `club_id`) | ✅ Coluna `club_id` adicionada em `V2` | V1 possui a tabela `platform.team`, mas **não possui** a coluna `club_id`. Em `TeamEntity.java`, existe `@Column(name = "club_id") private UUID clubId;`. |
| `platform.competitions` | `CompetitionEntity.java` | ✅ Presente com `season` | ✅ Alinhado | A coluna `season varchar(50) DEFAULT '2026' NOT NULL` **já está presente** na linha 187 de `V1__MomentZero.sql`. `CompetitionEntity` mapeia `private String season;`. |
| `platform.roster` | `RosterEntity.java` | ✅ Presente | ✅ Alinhado | Tabela existe em V1 (linha 249) com `team_id`, `competition_id`, `season`, `status` e unique constraint `uk_roster_team_competition`. Alinhada com `RosterEntity`. |
| `platform.team_roster` | `RosterEntryEntity.java` | ✅ Presente | ✅ Alinhado | Tabela existe em V1 (linha 307) com `roster_id`, `athlete_id`, `nickname`, `number`, `status`. Alinhada com `RosterEntryEntity`. |
| `platform.competition_team` | `CompetitionTeamEntity.java` | ✅ Presente | ✅ Alinhado | Tabela existe em V1 (linha 325) com `competition_id`, `team_id`, `division_id`. Alinhada com `CompetitionTeamEntity`. |
| `platform.users` | `UserEntity.java` | ⚠️ V1 com `password_hash` | ✅ Alterada em `V3`/`V4` | V1 tinha `password_hash varchar(255) NOT NULL`. `UserEntity` removeu esse campo devido à transição para Firebase Auth (ADR-004/ADR-008). |
| `platform.password_reset_tokens` | (Removido do domínio) | ⚠️ Presente em V1 | ✅ Removida em `V4` | Excluída em `V4` do Flyway Java. Não possui entidade correspondente. |
| `platform.athletes` | `AthleteEntity.java` | ✅ Presente | ✅ Alinhado | Perfeitamente mapeada com `platform.athlete_positions`. |
| `platform.venues` | `VenueEntity.java` | ✅ Presente | ✅ Alinhado | Perfeitamente mapeada. |
| `platform.games` | `GameEntity.java` | ✅ Presente | ✅ Alinhado | Mapeada. `scheduled_at` é anulável no banco e na entidade. |
| `platform.checkins` | `CheckInEntity.java` | ✅ Presente | ✅ Alinhado | Mapeada com `match_number`, `athlete_id`, `game_id`, `status`. |
| `platform.plays` | `PlayEntity.java` | ✅ Presente | ✅ Alinhado | Mapeada. |
| `platform.score_events` | `ScoreEventEntity.java` | ✅ Presente | ✅ Alinhado | Mapeada. |
| `platform.conferences` | `ConferenceEntity.java` | ✅ Presente | ✅ Alinhado | Mapeada. |
| `platform.divisions` | `DivisionEntity.java` | ✅ Presente | ✅ Alinhado | Mapeada. |
| `platform.rounds` | `RoundEntity.java` | ✅ Presente | ✅ Alinhado | Mapeada. |
| `platform.standings` | `StandingEntity.java` | ✅ Presente | ✅ Alinhado | Mapeada. |

---

## 3. Análise Detalhada dos Gaps de Schema

### 3.1 Gaps na Tabela `platform.institutions`
Em `InstitutionEntity.java`:
```java
@Table(name = "institutions", schema = "platform")
public class InstitutionEntity extends BaseEntity {
    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private InstitutionType type; // CLUB, UNIVERSITY

    @Column(columnDefinition = "text[]")
    private String[] colors;

    @Column(nullable = false)
    private String status;
}
```
Na migração Java `V5`:
- O ID foi definido sem valor default: `.column(DSL.field(DSL.name("id"), SQLDataType.UUID.nullable(false)))`.
  No PostgreSQL do projeto, a convenção em todas as PKs é `id uuid DEFAULT gen_random_uuid() NOT NULL`.
- Os campos de auditoria `created_by` e `updated_by` (herdados de `BaseEntity`) foram omitidos na tabela.

### 3.2 Gaps na Tabela `platform.institution_organizations`
Em `InstitutionOrganizationRepository.java`:
```java
SELECT organization_id FROM platform.institution_organizations WHERE institution_id = ?
INSERT INTO platform.institution_organizations(institution_id, organization_id) VALUES (?,?)
DELETE FROM platform.institution_organizations WHERE institution_id = ?
```
Requisitos essenciais:
- Chave primária composta `(institution_id, organization_id)`.
- Foreign keys com `ON DELETE CASCADE` para ambas as tabelas (`platform.institutions` e `platform.organizations`).
- Índice secundário em `organization_id` para otimização de consultas reversas (buscar agremiações de uma dada federação).

### 3.3 Gaps na Tabela `platform.team`
Em `TeamEntity.java`:
```java
@Column(name = "organization_id", nullable = false)
private UUID organizationId;

@Column(name = "club_id")
private UUID clubId;
```
No V1: A coluna `club_id` inexiste. Deve ser adicionada como `uuid NULL` com índice e FK opcional para `platform.clubs(id) ON DELETE SET NULL`.

### 3.4 Situação de `competition.season`, `roster` e `competition_team`
Diferente do que sugeriam os apontamentos preliminares:
- `platform.competitions.season` **já existe** no V1 (`season varchar(50) DEFAULT '2026'::character varying NOT NULL`).
- `platform.roster` **já existe** no V1 com todas as colunas necessárias e constraint `uk_roster_team_competition`.
- `platform.competition_team` **já existe** no V1 com constraint `uk_competition_team`.
- A inclusão de cláusulas `IF NOT EXISTS` para essas colunas/tabelas garante idempotência absoluta sem riscos de quebra.

---

## 4. Análise de Estratégias de Implementação

Existem duas estratégias técnicas viáveis para consolidar a evolução do schema:

### Estratégia 1: Consolidação Canônica em SQL Nativo (`V2__Refactor_Schema.sql`) — RECOMENDADA
- **Ação:**
  1. Criar o arquivo `src/main/resources/db/migration/V2__Refactor_Schema.sql` com todo o DDL consolidado.
  2. **REMOVER** os arquivos Java de migração em `src/main/java/db/migration/` (`V2__CreateClubsAndRefactorTeams.java`, `V3__MakeUsersPasswordHashNullable.java`, `V4__RemovePasswordHashAndResetTokens.java`, `V5__CreateInstitutionsAndInstitutionOrganizations.java`).
- **Vantagens:**
  - Elimina o conflito de versões no Flyway (`Found more than one migration with version 2`).
  - Centraliza todas as migrações em SQL padrão declarativo, facilitando inspeção por administradores de banco, ferramentas de CI/CD e testes E2E externos.
  - Elimina dependência de compilação Java prévia do Flyway no boot.
  - Alinha-se perfeitamente à convenção do `V1__MomentZero.sql`.

### Estratégia 2: Preservação das Migrações Java (ADR-007) com Migração Adicional (`V6`)
- **Ação:**
  - Manter as migrações `V2` a `V5` em Java/jOOQ e criar uma nova migração incremental: `V6__Sync_Missing_Audit_And_Defaults.sql` (ou `V6...java`).
- **Desvantagens:**
  - Mantém histórico fragmentado em duas linguagens (SQL e Java).
  - Viola o comando do usuário que solicita especificamente o DDL de `V2__Refactor_Schema.sql`.

---

## 5. Especificação Exata do DDL para `V2__Refactor_Schema.sql`

O script abaixo consolida com máxima robustez todas as alterações estruturais pós-V1, respeitando a integridade referencial do PostgreSQL, adicionando índices adequados e garantindo total idempotência via blocos anônimos PL/pgSQL e cláusulas `IF NOT EXISTS`:

```sql
-- ============================================================================
-- Migration V2: Refactor Schema & Align Domain Hierarchy
-- Consolidates Post-MomentZero Evolutions:
--   1. platform.clubs (Clubs under Organizations)
--   2. platform.team (Add club_id reference & index)
--   3. platform.institutions (Institutions: Clubs & Universities)
--   4. platform.institution_organizations (Affiliation Junction)
--   5. platform.competitions (Idempotent season enforcement)
--   6. platform.roster (Idempotent season enforcement)
--   7. platform.users & password_reset_tokens (Firebase Auth alignment)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Create platform.clubs
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform.clubs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    "name" varchar(255) NOT NULL,
    short_name varchar(50) NULL,
    sport_name varchar(255) NULL,
    logo_url varchar(500) NULL,
    "document" varchar(20) NULL,
    document_type varchar(10) NULL,
    president_name varchar(150) NULL,
    president_cpf varchar(14) NULL,
    status varchar(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp NULL,
    created_by uuid NULL,
    updated_by uuid NULL,
    CONSTRAINT clubs_pkey PRIMARY KEY (id),
    CONSTRAINT fk_clubs_organization FOREIGN KEY (organization_id) REFERENCES platform.organizations(id) ON DELETE CASCADE,
    CONSTRAINT ck_clubs_status CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('INACTIVE'::character varying)::text])))
);

CREATE INDEX IF NOT EXISTS idx_clubs_organization_id ON platform.clubs USING btree (organization_id);
CREATE UNIQUE INDEX IF NOT EXISTS uk_clubs_document ON platform.clubs USING btree (document) WHERE (document IS NOT NULL);

-- ----------------------------------------------------------------------------
-- 2. Alter platform.team (Add club_id reference)
-- ----------------------------------------------------------------------------
ALTER TABLE platform.team ADD COLUMN IF NOT EXISTS club_id uuid NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'fk_team_club' 
          AND conrelid = 'platform.team'::regclass
    ) THEN
        ALTER TABLE platform.team
            ADD CONSTRAINT fk_team_club FOREIGN KEY (club_id) REFERENCES platform.clubs(id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_team_club_id ON platform.team USING btree (club_id);

-- ----------------------------------------------------------------------------
-- 3. Create platform.institutions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform.institutions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "name" varchar(255) NOT NULL,
    "type" varchar(20) NOT NULL,
    colors text[] NULL,
    status varchar(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp NULL,
    created_by uuid NULL,
    updated_by uuid NULL,
    CONSTRAINT institutions_pkey PRIMARY KEY (id),
    CONSTRAINT ck_institutions_type CHECK (((type)::text = ANY (ARRAY[('CLUB'::character varying)::text, ('UNIVERSITY'::character varying)::text]))),
    CONSTRAINT ck_institutions_status CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('INACTIVE'::character varying)::text])))
);

CREATE INDEX IF NOT EXISTS idx_institutions_type ON platform.institutions USING btree (type);

-- ----------------------------------------------------------------------------
-- 4. Create platform.institution_organizations
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform.institution_organizations (
    institution_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid NULL,
    CONSTRAINT institution_organizations_pkey PRIMARY KEY (institution_id, organization_id),
    CONSTRAINT fk_inst_org_institution FOREIGN KEY (institution_id) REFERENCES platform.institutions(id) ON DELETE CASCADE,
    CONSTRAINT fk_inst_org_organization FOREIGN KEY (organization_id) REFERENCES platform.organizations(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_inst_org_organization_id ON platform.institution_organizations USING btree (organization_id);

-- ----------------------------------------------------------------------------
-- 5. Enforce Season in platform.competitions & platform.roster (Idempotent)
-- ----------------------------------------------------------------------------
ALTER TABLE platform.competitions ADD COLUMN IF NOT EXISTS season varchar(50) DEFAULT '2026'::character varying NOT NULL;
ALTER TABLE platform.roster ADD COLUMN IF NOT EXISTS season varchar(50) DEFAULT '2026'::character varying NOT NULL;

-- ----------------------------------------------------------------------------
-- 6. Firebase Auth Migration Alignment (ADR-004 & ADR-008)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS platform.password_reset_tokens;

ALTER TABLE platform.users DROP COLUMN IF EXISTS password_hash;
```

---

## 6. Plano de Ação Recomendado para o Worker de Implementação

1. **Adicionar o Arquivo de Migração SQL:**
   - Criar `src/main/resources/db/migration/V2__Refactor_Schema.sql` com o conteúdo exato da Seção 5.
2. **Remover Migrações Java Redundantes (para evitar colisão de versão Flyway):**
   - Excluir os 4 arquivos em `src/main/java/db/migration/`:
     - `V2__CreateClubsAndRefactorTeams.java`
     - `V3__MakeUsersPasswordHashNullable.java`
     - `V4__RemovePasswordHashAndResetTokens.java`
     - `V5__CreateInstitutionsAndInstitutionOrganizations.java`
3. **Validar a Compilação do Backend:**
   - Executar `./mvnw clean compile` no repositório `flag_backend`.
   - Garantir 0 erros de compilação e verificação de classes.
4. **Verificar Configuração do Flyway:**
   - Em `application.yml`, confirmar que `locations: classpath:db/migration` continuará localizando `V1__MomentZero.sql` e `V2__Refactor_Schema.sql`.
