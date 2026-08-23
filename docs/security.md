# Segurança da fundação GOV TOTAL

## Modelo de ameaça e fronteira de confiança

`organization_id` é a fronteira obrigatória de isolamento. O navegador, a organização selecionada na interface e qualquer valor enviado pelo cliente são não confiáveis. O PostgreSQL/Supabase é responsável pela autorização efetiva.

Objetivos desta fundação:

- impedir leitura e escrita cross-tenant;
- impedir que uma atualização troque `organization_id`;
- permitir papéis diferentes por organização e por departamento;
- negar acesso a vínculo ausente, inativo, suspenso ou fora da vigência;
- evitar criação concorrente de números duplicados;
- registrar alterações de negócio em log append-only;
- impedir alteração de versões concluídas/aprovadas;
- reservar operações críticas para RPCs verificadas.

## RLS deny-by-default

Todas as tabelas públicas da fundação possuem `ENABLE ROW LEVEL SECURITY` e `FORCE ROW LEVEL SECURITY`. Grants são explícitos e limitados. Tabelas sem política compatível ficam inacessíveis por padrão.

O acesso combina:

1. `auth.uid()` autenticado;
2. vínculo ativo em `organization_members`;
3. papel vigente em `member_role_assignments`;
4. permissão atômica em `role_permissions`;
5. escopo de organização ou departamento;
6. condição específica do recurso.

Um assignment com `department_id is null` vale para toda a organização. Um assignment departamental vale somente quando o recurso pertence ao mesmo departamento.

## Permissões iniciais

- `organization.read`
- `organization.manage`
- `department.read`
- `department.manage`
- `member.read`
- `member.manage`
- `role.manage`
- `process.read`
- `process.create`
- `process.update`
- `process.archive`
- `audit.read`

Papéis são tenant-owned e extensíveis. Nenhuma política autoriza pelo nome do papel.

## Proteções cross-tenant

- tabelas filhas usam FKs compostas `(organization_id, id)` quando relacionam entidades tenant-owned;
- triggers rejeitam mudança de `organization_id` em tabelas mutáveis;
- a RPC de criação valida vínculo, permissão e departamento dentro do mesmo tenant;
- numeração é particionada por `(organization_id, process_year)`;
- policies de versões derivam o departamento do processo pai;
- índices começam por `organization_id` nos caminhos de consulta principais.

## Funções SECURITY DEFINER

A migration contém apenas três usos intencionais:

| Função | Motivo | Exposição |
|---|---|---|
| `is_active_organization_member` | consultar membership sob RLS | `authenticated` |
| `has_permission` | resolver RBAC sob RLS | `authenticated` |
| `write_audit_event` | inserir auditoria sem liberar insert ao cliente | somente triggers |
| `create_procurement_process` | operação crítica, numeração atômica e autorização | `authenticated` |

Todas usam `search_path = pg_catalog, public`, objetos qualificados, parâmetros tipados e grants mínimos. `write_audit_event` não pode ser chamada pelo usuário. `create_procurement_process` não aceita requester arbitrário; deriva usuário e membership de `auth.uid()`.

Revisão obrigatória para futuras funções:

- justificar por que `SECURITY INVOKER` não é suficiente;
- fixar `search_path`;
- qualificar tabelas/funções;
- revogar execução de `public` e `anon`;
- validar tenant dentro da função;
- nunca aceitar `created_by`, `actor_user_id` ou membership como identidade confiável do cliente;
- adicionar teste negativo cross-tenant.

## Operações críticas

Criação de processo ocorre por `create_procurement_process`. Não há grant de `INSERT` direto em `procurement_processes`. O contador não possui grant ou policy para clientes.

Provisionamento inicial de organização, primeiro administrador, roles e permissions será uma operação administrativa de servidor/service role. Não deve ser exposta diretamente ao navegador antes de existir uma RPC de bootstrap revisada e idempotente.

Conclusão/aprovação de versão, arquivamento privilegiado, workflow de aprovação e assinatura ainda não foram implementados. Devem ser RPCs próprias, não updates genéricos.

## Auditoria

`audit_events` é append-only para usuários da aplicação:

- cliente possui apenas `SELECT`, condicionado a `audit.read`;
- não existem policies/grants de insert, update ou delete;
- triggers inserem eventos sanitizados;
- metadados iniciais registram somente a origem do evento;
- identidade deriva de `auth.uid()`;
- `correlation_id` pode ser propagado por contexto transacional confiável.

Não registrar tokens, senhas, segredos, conteúdo de anexos ou dados pessoais desnecessários. Expansão do diff deve passar por classificação e política de retenção.

## Classificação da informação

Valores iniciais:

- `public`: publicável conforme decisão do órgão;
- `internal`: uso interno ordinário;
- `restricted`: acesso limitado por função/processo;
- `personal_sensitive`: dado pessoal ou sensível sujeito a controles adicionais.

A classificação existe em organização, processo e versão. Esta primeira migration não implementa ABAC completo por classificação; isso é um risco conhecido antes de exposição de dados restritos/pessoais em produção.

## Arquivamento e exclusão

Processos e documentos usam status/`archived_at`. Usuários comuns não recebem `DELETE`. Exclusão definitiva deverá ser excepcional, executada por função privilegiada, exigir justificativa e gerar evento de auditoria. FKs usam `ON DELETE RESTRICT` para evitar cascatas destrutivas.

## Testes de segurança

`supabase/tests/foundation_rls_test.sql` cobre:

- A lê A e não lê B;
- A não cria nem atualiza B;
- `organization_id` não pode ser trocado;
- usuário sem vínculo não acessa organização;
- vínculo inativo não acessa organização;
- membro sem `process.create` não cria;
- usuário autorizado cria;
- sequência por organização/ano;
- geração de evento de auditoria;
- usuário comum não altera auditoria.

Executar em CI e localmente após `supabase db reset`. Adicionar testes de concorrência real para numeração antes de produção; o teste SQL atual verifica sequência, enquanto a garantia de concorrência deriva do `INSERT ... ON CONFLICT DO UPDATE` com lock de linha do PostgreSQL.

## Ambientes

Manter projetos/segredos separados:

- local/dev: dados sintéticos;
- staging/demo: dados demonstrativos, nunca cópia não sanitizada de produção;
- produção: projeto isolado, backups, PITR conforme contrato e região aprovada.

Nunca reutilizar service-role keys entre ambientes nem expô-las em variáveis `VITE_*`.

## Pendências para produção

- testar migrations em Supabase local e CI;
- criar matriz tabela × operação × permissão;
- implementar bootstrap administrativo seguro;
- definir ABAC para `restricted`/`personal_sensitive`;
- adicionar RPCs de arquivamento e conclusão/versionamento;
- testar concorrência de numeração com múltiplas conexões;
- definir retenção de auditoria, backup, restauração e resposta a incidentes;
- revisar policies e funções por segunda pessoa antes do GO de produção.

## Diário Oficial e leitura pública

O acervo do Diário usa defesa em profundidade:

- bucket `official-gazette` privado;
- `anon` recebe somente `SELECT` de linhas ligadas a edição `published` ou `revoked`;
- rascunhos exigem vínculo ativo e permissões `gazette.read`/`gazette.manage`;
- publicação exige a RPC `publish_official_gazette` e a permissão `gazette.publish`;
- `organization_id` é imutável e FKs compostas evitam vínculos cross-tenant;
- triggers bloqueiam update/delete destrutivo após a publicação;
- alterações geram `audit_events` append-only.

A função de publicação é `SECURITY DEFINER` apenas por precisar conferir o arquivo no schema privado do Storage e executar a transição atômica. Ela fixa `search_path`, deriva o ator de `auth.uid()`, revalida tenant/permissão e não é executável por `anon` ou `PUBLIC`.

O SHA-256 do conteúdo textual é calculado no PostgreSQL. O SHA-256 do arquivo é calculado no navegador antes do upload e armazenado como metadado; validação criptográfica servidor-side do binário ainda é uma pendência antes de produção.
