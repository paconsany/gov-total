# Banco de dados GOV TOTAL

## Escopo implementado

Migration: `supabase/migrations/20260822210000_foundation.sql`

Esta fundação implementa organização, departamentos, usuários/vínculos, RBAC, processos, versionamento-base, auditoria e isolamento multi-tenant. Conteúdo completo de Demanda, DFD, ETP, Matriz de Riscos, Pesquisa de Preços e TR permanece no frontend.

## Tabelas

| Tabela | Papel |
|---|---|
| `profiles` | nome de exibição mínimo ligado a `auth.users` |
| `organizations` | tenant/órgão público |
| `departments` | hierarquia de secretarias, departamentos e setores |
| `organization_members` | vínculo independente de usuário com organização |
| `roles` | papéis extensíveis por organização |
| `permissions` | permissões atômicas globais |
| `role_permissions` | permissões concedidas a um papel |
| `member_role_assignments` | papel do membro em escopo de organização/departamento |
| `process_number_counters` | contador concorrente por organização e ano |
| `procurement_processes` | processo principal de contratação |
| `process_versions` | fundação versionada para Demanda, DFD, ETP, Pesquisa e TR |
| `audit_events` | trilha append-only |

## Relacionamentos principais

```text
auth.users ── profiles
auth.users ── organization_members ── organizations
organization_members ── member_role_assignments ── roles
roles ── role_permissions ── permissions
organizations ── departments (parent_id hierárquico)
organizations ── process_number_counters
organizations ── procurement_processes ── process_versions
departments ── procurement_processes
organization_members ── procurement_processes (requester)
organizations ── audit_events
```

FKs compostas garantem que departamento, requester, role e membership pertencem à mesma organização do registro filho.

## Numeração pública

`create_procurement_process` executa:

1. valida autenticação;
2. busca membership ativo na organização;
3. exige `process.create` no escopo do departamento;
4. valida departamento ativo no tenant;
5. incrementa `process_number_counters` via upsert atômico;
6. insere o processo e retorna o registro.

Formato gerado: `lpad(sequence_number, 6, '0') || '/' || process_year`, por exemplo `000001/2026`.

Não é usado `count(*) + 1`. O conflito no contador serializa atualizações concorrentes na mesma organização/ano.

## Versionamento-base

`process_versions` suporta:

- tipos `demand`, `dfd`, `etp`, `price_research`, `term_reference`;
- número e versão de schema;
- `content jsonb` objeto;
- draft único por processo/tipo;
- classificação da informação;
- conclusão e aprovação separadas;
- hash e resumo da mudança;
- lock otimista;
- imutabilidade depois de concluída/aprovada.

Ainda não existem RPCs de criar/concluir/aprovar versão nem schemas JSON de cada documento. Eles serão implementados somente com autorização posterior.

## Aplicação da migration

Pré-requisito futuro: Supabase CLI e Docker em ambiente local.

```bash
supabase init
supabase start
supabase db reset
supabase test db
```

Para ambiente remoto, usar pipeline controlado e projeto correto por ambiente. Não executar migration manual em produção antes de passar por local, CI e staging.

## Testes

Arquivo: `supabase/tests/foundation_rls_test.sql`.

O teste é transacional e termina em `ROLLBACK`. Cria dois tenants e usuários com diferentes estados/permissões. Deve ser executado após a migration.

Nesta sessão, os testes de banco **não foram executados**, pois não há Supabase CLI, `psql`, Docker ou Podman acessível. TypeScript e build do frontend continuam sendo executados separadamente.

## Bootstrap inicial

Ainda não há endpoint/RPC de autosserviço para criar organização. O bootstrap inicial deve ser feito por operação administrativa confiável:

1. inserir organização;
2. inserir departamentos iniciais;
3. inserir membership do administrador;
4. criar roles do tenant;
5. atribuir permissions aos roles;
6. atribuir papel organizacional ao administrador.

Antes de disponibilizar onboarding, criar uma RPC de bootstrap idempotente, restrita ao backend/service role e coberta por auditoria/testes.

## Convenções

- UUID para identidade;
- `timestamptz` para timestamps;
- `numeric(19,4)` para moeda/quantidades financeiras;
- enums PostgreSQL para estados fundacionais estáveis;
- texto + validação de domínio futura para catálogos mais mutáveis;
- exclusão lógica e `ON DELETE RESTRICT`;
- `created_by`/`updated_by` derivados do usuário autenticado quando aplicável;
- nomes SQL em `snake_case` e permissões em `resource.action`.

## Próxima vertical autorizável

Após execução real e aprovação dos testes, a primeira integração recomendada é:

1. autenticação e seleção de organização;
2. listagem/criação de `procurement_processes` pela RPC;
3. persistência versionada da Demanda;
4. somente depois DFD e demais documentos.

O frontend atual não deve ser conectado antes de o ambiente Supabase local/staging comprovar RLS e bootstrap.
