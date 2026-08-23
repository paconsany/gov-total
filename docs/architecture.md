# Arquitetura de dados do GOV TOTAL

**Status:** decisões aprovadas; fundação implementada em migration, ainda não executada em banco local  
**Escopo:** fundação Supabase/PostgreSQL para transformar o protótipo em software multi-organização  
**Última revisão:** 22 de agosto de 2026

## 1. Visão geral

O GOV TOTAL deve ser uma aplicação multi-tenant em que uma mesma instalação atende prefeituras, consórcios e outros órgãos públicos, mantendo isolamento rigoroso entre organizações. O Supabase fornecerá PostgreSQL, autenticação e, futuramente, Storage. A autorização não dependerá do frontend: será aplicada no banco por Row Level Security (RLS).

A arquitetura proposta usa três camadas de dados:

1. **Núcleo relacional:** organizações, departamentos, usuários, vínculos, papéis, permissões, processos, itens, referências de preços, riscos e metadados de documentos. São dados usados em filtros, relacionamentos, segurança e relatórios.
2. **Documentos versionados com conteúdo estruturado:** DFD, ETP, Pesquisa de Preços e TR possuem um registro estável e versões imutáveis. Cada versão combina colunas de controle com um `content jsonb` validado pela aplicação. Isso permite evolução dos formulários sem criar uma tabela para cada campo.
3. **Eventos e auditoria:** trilha append-only para registrar quem alterou o quê, quando e em qual organização/processo, sem depender apenas de `updated_at`.

Princípios:

- todo dado de negócio pertence explicitamente a uma `organization_id`;
- `organization_id` nunca é aceito cegamente do cliente: políticas e funções validam o vínculo do usuário;
- documentos aprovados não são sobrescritos; uma mudança gera nova versão;
- listas com identidade e auditoria próprias ficam em tabelas relacionais;
- conteúdo documental de baixa necessidade de consulta transversal pode ficar em JSONB versionado;
- cálculos críticos são reproduzíveis e guardam entradas, método e resultado;
- timestamps usam `timestamptz`, valores monetários usam `numeric`, e identificadores usam UUID;
- exclusão de registros de negócio deve ser preferencialmente lógica (`archived_at`/`deleted_at`) e auditada.

## 2. Estado atual do frontend

Não há `localStorage`, `sessionStorage`, API ou persistência. Ao recarregar a página, todo o processo é perdido. Os estados encontrados são:

### Navegação e interface (não persistir como domínio)

- página/etapa atual, sidebar móvel, filtros e busca;
- seções abertas do TR e painéis abertos da Pesquisa de Preços;
- mensagens temporárias de “salvo”;
- filtro da Revisão Inteligente e seção do TR em foco;
- página de retorno ao fechar a revisão.

Esses estados podem permanecer no frontend. Opcionalmente, a etapa atual pode ser refletida na URL. Não devem virar tabelas.

### Processo e Demanda

- título, objeto, secretaria, setor, responsável, e-mail e telefone;
- tipo, prioridade, data desejada e valor preliminar;
- necessidade, problema, resultado esperado;
- previsão no PCA e identificação do item;
- itens de escopo: descrição, quantidade, unidade e observação.

### DFD

- justificativa, benefícios, alinhamento estratégico, programa/ação orçamentária;
- fonte do valor preliminar, contratação continuada, prazo contratual;
- risco inicial da não contratação, elaborador, autoridade de encaminhamento e status;
- ano do PCA;
- riscos iniciais simples e itens/escopo compartilhados.

### ETP

- solução recomendada, descrição, justificativa da escolha e rejeição das alternativas;
- natureza, metodologia, fontes, data-base, parcelamento e justificativa;
- resultados e benefícios, sustentabilidade, impactos e mitigação;
- conclusão de viabilidade, elaborador e status;
- requisitos, alternativas, contratações relacionadas, indicadores e providências prévias.

### Matriz de Riscos

- observações e status da matriz;
- riscos com categoria, fase, probabilidade, impacto, responsáveis, prevenção, contingência, prazo e status.

### Pesquisa de Preços

- conclusão, justificativa da metodologia, responsável e status;
- cópia ajustável dos itens pesquisados e metodologia por item;
- referências, fonte, fornecedor/órgão, CNPJ, quantidade, valores, data, identificador;
- decisão de considerar/desconsiderar, motivo e justificativa.

### Termo de Referência

- modelo de execução, prazos, local, restrições e obrigações;
- SLA opcional;
- gestão/fiscalização, medição, aceite e pagamento;
- seleção do fornecedor, qualificação, orçamento e conclusão;
- marcos de execução e níveis de serviço;
- requisitos compartilhados com o ETP.

### Revisão Inteligente

- regras determinísticas calculadas no cliente;
- apontamentos derivados, severidade, etapa, descrição e sugestão;
- marcações locais de “revisado”.

No backend, uma execução da revisão deverá guardar o conjunto exato de versões analisadas e seus apontamentos. “Revisado” continuará distinto de “resolvido”.

## 3. Entidades propostas

### 3.1 Tenant, identidade e autorização

| Entidade | Finalidade | Campos principais |
|---|---|---|
| `organizations` | Tenant/órgão público | `id`, `name`, `legal_name`, `document_number`, `type`, `slug`, `status`, metadados de auditoria |
| `departments` | Secretaria, departamento ou setor hierárquico | `id`, `organization_id`, `parent_id`, `name`, `code`, `type`, `active` |
| `profiles` | Dados públicos complementares a `auth.users` | `user_id`, `display_name`, `email`, `active` |
| `organization_memberships` | Vínculo de usuário com organização | `id`, `organization_id`, `user_id`, `default_department_id`, `status`, datas de vigência |
| `roles` | Papel configurável, global do sistema ou específico do tenant | `id`, `organization_id` nullable, `key`, `name`, `description`, `system_role` |
| `permissions` | Capacidade atômica | `id`, `key`, `description`, `resource`, `action` |
| `role_permissions` | Permissões concedidas ao papel | `role_id`, `permission_id` |
| `membership_roles` | Papéis de um vínculo | `membership_id`, `role_id`, escopo opcional de departamento |

Papéis iniciais serão seeds configuráveis, não condicionais fixos no código: Administrador da organização, Gestor, Requisitante, Equipe de planejamento, Compras/Licitação, Fiscal/Controle e Consulta.

Permissões devem ser granulares, por exemplo: `process.read`, `process.create`, `demand.edit`, `dfd.submit`, `etp.approve`, `price_research.edit`, `tr.review`, `audit.read`, `membership.manage`. Um usuário pode ter mais de um papel.

### 3.2 Processo de contratação

| Entidade | Finalidade | Campos principais |
|---|---|---|
| `procurement_processes` | Agregado principal | `id`, `organization_id`, `number`, `year`, `title`, `object`, `requesting_department_id`, `requester_membership_id`, `process_type`, `priority`, `current_stage`, `status`, `desired_date`, `preliminary_value`, PCA, auditoria |
| `process_participants` | Pessoas/equipes relacionadas | `process_id`, `membership_id`, `participant_role`, `department_id`, vigência |
| `process_items` | Escopo canônico do processo | `id`, `organization_id`, `process_id`, `item_number`, `description`, `quantity`, `unit`, `notes`, `active` |
| `process_stage_transitions` | Histórico de avanço/retorno | `id`, `organization_id`, `process_id`, `from_stage`, `to_stage`, `reason`, autor e data |

`procurement_processes` guarda apenas campos de identificação e consulta frequente. Conteúdo extenso pertence aos documentos versionados.

### 3.3 Demanda e documentos de planejamento

| Entidade | Finalidade |
|---|---|
| `demands` | Dados atuais da demanda; permanece editável antes de formalização e pode futuramente ganhar versão própria |
| `process_documents` | Identidade estável de cada documento (`dfd`, `etp`, `price_research`, `tr`) por processo |
| `document_versions` | Versões imutáveis com `version_number`, `content jsonb`, estado e hash |
| `document_version_links` | Liga uma versão a versões anteriores que serviram de fonte |

Campos recomendados de `process_documents`:

- `id`, `organization_id`, `process_id`, `document_type`;
- `current_draft_version_id`, `latest_approved_version_id`;
- `status`, `created_at/by`, `updated_at/by`;
- restrição única `(process_id, document_type)`.

Campos recomendados de `document_versions`:

- `id`, `organization_id`, `document_id`, `version_number`;
- `schema_version` para evoluir o formato do JSONB;
- `content jsonb`;
- `status`: `draft`, `ready_for_review`, `approved`, `superseded`, `cancelled`;
- `change_summary`, `content_hash`;
- `created_at/by`, `submitted_at/by`, `approved_at/by`;
- restrição única `(document_id, version_number)`.

O JSONB de cada documento deve seguir schemas TypeScript/Zod versionados no código. Campos usados em filtros e relatórios devem ser promovidos para colunas ou tabelas, não consultados indefinidamente dentro de JSONB.

### 3.4 Entidades relacionais de conteúdo

Algumas listas merecem tabelas próprias porque são consultadas, calculadas ou auditadas individualmente:

| Entidade | Relacionamento |
|---|---|
| `etp_requirements` | versão do ETP; título, descrição, tipo e ordem |
| `etp_alternatives` | versão do ETP; alternativa, vantagens, desvantagens, custo e viabilidade |
| `etp_related_contracts` | versão do ETP; contratação correlata/interdependente |
| `etp_indicators` | versão do ETP; indicador, meta e medição |
| `etp_preparations` | versão do ETP; providência, responsável, prazo e estado |
| `risk_matrices` | identidade/estado da matriz do processo |
| `risk_matrix_versions` | versão imutável da matriz e conclusão |
| `risks` | versão da matriz; risco, avaliação, tratamento, responsável e estado |
| `price_research_items` | versão da pesquisa; item, quantidade, método e valor calculado |
| `price_references` | item pesquisado; fonte, valores, validade e justificativa de descarte |
| `tr_requirements` | referência ou snapshot dos requisitos usados na versão do TR |
| `tr_milestones` | versão do TR; marco, prazo, entregável e aceite |
| `tr_service_levels` | versão do TR; indicador, meta, medição, periodicidade e consequência |

Decisão importante: `process_items` é o escopo canônico. Pesquisa e TR referenciam `process_item_id`, mas guardam snapshots de descrição, quantidade e unidade na versão para preservar o que foi aprovado naquele momento.

### 3.5 Aprovações futuras

Planejar, sem implementar agora:

| Entidade | Finalidade |
|---|---|
| `approval_workflows` | Modelo de fluxo por organização/tipo de processo |
| `approval_steps` | Etapas e ordem do modelo |
| `approval_requests` | Execução do fluxo para documento/versão |
| `approval_decisions` | Decisão, observação, responsável e data |

Uma aprovação sempre aponta para uma versão imutável, nunca apenas para o documento atual.

### 3.6 Revisão Inteligente

| Entidade | Finalidade |
|---|---|
| `review_rules` | Catálogo versionado de regras determinísticas/IA futura |
| `review_runs` | Execução da revisão e snapshot das versões analisadas |
| `review_findings` | Apontamentos gerados pela execução |
| `review_finding_events` | Histórico de reconhecimento, resolução, reabertura ou descarte justificado |

`review_runs` deve guardar `engine_version`, `rule_set_version`, `started_at`, `completed_at`, `triggered_by`, `health`, contagens e um `input_manifest jsonb` com IDs/hashes das versões analisadas. Assim, o resultado pode ser reproduzido.

`review_findings` deve guardar `rule_key`, `type`, `stage`, `severity`, `description`, `suggested_action`, `target_path`, `status` e referência opcional ao registro/campo. Status sugeridos: `open`, `acknowledged`, `resolved`, `dismissed`. “Marcar como revisado” cria evento `acknowledged`; não resolve.

## 4. Diagrama textual

```text
auth.users
  │
  ├── profiles
  │
  └── organization_memberships ── membership_roles ── roles
                │                                      │
                │                                      └── role_permissions ── permissions
                │
organizations ──┼── departments (hierárquicos)
  │             │
  │             └── process_participants
  │
  └── procurement_processes
        ├── demands
        ├── process_items
        ├── process_stage_transitions
        ├── process_documents
        │     └── document_versions
        │           ├── document_version_links
        │           ├── etp_requirements
        │           ├── etp_alternatives
        │           ├── etp_related_contracts
        │           ├── etp_indicators
        │           ├── etp_preparations
        │           ├── price_research_items ── price_references
        │           ├── tr_requirements
        │           ├── tr_milestones
        │           └── tr_service_levels
        ├── risk_matrices ── risk_matrix_versions ── risks
        ├── review_runs ── review_findings ── review_finding_events
        ├── attachments
        └── approval_requests ── approval_decisions  (futuro)

Todas as entidades de negócio carregam organization_id.
```

## 5. Estratégia multi-tenant

### 5.1 Isolamento

- modelo compartilhado (`public`) com `organization_id` em todas as tabelas de negócio;
- vínculo autorizado em `organization_memberships` com estado `active`;
- políticas RLS consultam o vínculo pelo `auth.uid()`;
- chaves compostas e triggers impedem relacionamentos entre tenants diferentes;
- índices começam por `organization_id` nos padrões de consulta mais frequentes;
- unicidades sensíveis são por tenant, como `(organization_id, year, number)`;
- seleção de organização no frontend só muda contexto; não concede acesso.

### 5.2 Integridade entre tenants

Uma FK simples para `process_id` não prova que o filho possui o mesmo tenant. Adotar uma destas abordagens, preferencialmente a primeira:

1. chaves únicas compostas `(organization_id, id)` no pai e FKs compostas no filho;
2. trigger `before insert/update` que valida a organização do pai.

Isso reduz o risco de um bug de aplicação associar dados da Prefeitura A a um processo da Prefeitura B.

### 5.3 Contexto ativo

O frontend terá um `OrganizationProvider` com a organização selecionada dentre os vínculos retornados pelo banco. Queries sempre filtram por esse ID, mas RLS continua sendo a barreira definitiva. Não colocar listas extensas de organizações/papéis em JWT como única fonte de autorização, pois claims podem ficar desatualizados.

## 6. Usuários e RBAC

`auth.users` é a identidade de autenticação. `profiles` não replica senha ou credenciais. A autorização deriva do vínculo ativo e das permissões associadas aos papéis naquele tenant.

Fluxo de decisão:

```text
usuário autenticado
  → possui vínculo ativo com a organização?
  → possui papel aplicável ao recurso/departamento?
  → o papel concede a permissão atômica?
  → a política adicional do recurso permite a operação?
```

Recomendações:

- papel pode ter escopo de organização e, opcionalmente, departamento;
- administradores gerenciam papéis do tenant, mas não permissões reservadas da plataforma;
- funções SQL `security definer` pequenas, estáveis e com `search_path` fixo podem centralizar `is_org_member(org_id)` e `has_permission(org_id, permission_key, department_id)`;
- proibir concessão de papéis de outra organização por FK/trigger;
- manter cache de autorização somente como otimização, nunca como fonte exclusiva.

## 7. Estratégia de RLS

RLS deve ser ativada em todas as tabelas expostas ao cliente. O `service_role` nunca vai para o navegador.

Política conceitual de leitura:

```sql
using (
  exists (
    select 1
    from organization_memberships m
    where m.organization_id = target.organization_id
      and m.user_id = auth.uid()
      and m.status = 'active'
  )
  and has_permission(target.organization_id, 'resource.read', target.department_id)
)
```

Escrita usa `with check` equivalente e permissão específica (`create`, `edit`, `submit`, `approve`). Regras adicionais:

- versões aprovadas: negar `update/delete` ao cliente;
- auditoria: apenas `select` para quem possui `audit.read`; inserts vêm de triggers/funções;
- memberships/RBAC: somente `membership.manage`/`role.manage` dentro do tenant;
- anexos: usuário precisa acessar o registro pai e ter permissão compatível;
- revisões: acesso condicionado ao processo e à permissão `review.read/run/manage`;
- Storage futuro deverá repetir o controle no bucket e nos metadados, não confiar apenas em URLs.

Antes das migrations, produzir uma matriz formal **tabela × operação × permissão × condição** e testes automatizados com pelo menos dois tenants e usuários com papéis diferentes.

## 8. Auditoria

Todas as tabelas mutáveis de domínio recebem:

- `created_at timestamptz not null default now()`;
- `created_by uuid` referenciando `auth.users` ou perfil técnico;
- `updated_at timestamptz not null default now()`;
- `updated_by uuid`;
- opcionalmente `archived_at`, `archived_by`.

Além disso, `audit_events` será append-only:

- `id`, `organization_id`, `occurred_at`, `actor_user_id`, `actor_membership_id`;
- `action`, `entity_type`, `entity_id`, `process_id`;
- `before_data jsonb`, `after_data jsonb` ou diff normalizado;
- `request_id`, `correlation_id`, `source`, `ip_hash` quando juridicamente apropriado;
- `metadata jsonb`.

Triggers podem capturar alterações diretas, mas ações de negócio importantes também geram eventos semânticos, por exemplo `dfd_submitted`, `document_version_approved`, `price_reference_discarded` e `finding_acknowledged`.

Cuidados:

- não registrar tokens, senhas ou dados desnecessários;
- avaliar retenção, LGPD e volume antes de guardar snapshots completos para todas as tabelas;
- tornar eventos imutáveis para usuários comuns;
- usar `request_id` para agrupar várias mudanças da mesma operação.

## 9. Versionamento

DFD, ETP, Pesquisa de Preços e TR seguem o mesmo ciclo:

1. documento estável é criado para o processo;
2. versão `draft` pode ser atualizada durante edição;
3. ao enviar para revisão, a versão é congelada ou clonada;
4. aprovação define `approved_at/by` e `content_hash`;
5. alteração posterior cria versão N+1 baseada na aprovada;
6. versão anterior permanece legível e auditável.

Listas relacionais pertencem à versão, não somente ao processo. Uma versão aprovada nunca deve apontar para linhas mutáveis compartilhadas sem snapshot. `document_version_links` registra dependências, por exemplo:

```text
TR v2
  ← DFD v1
  ← ETP v3
  ← Matriz de Riscos v2
  ← Pesquisa de Preços v2
```

Assim é possível provar exatamente quais conteúdos formaram o TR.

Concorrência: usar `lock_version bigint` ou comparação de `updated_at`/ETag no draft para impedir que duas abas sobrescrevam mudanças silenciosamente.

## 10. Anexos

Planejar `attachments` antes de habilitar Storage:

- `id`, `organization_id`, `process_id`;
- entidade e versão alvo (`entity_type`, `entity_id`, `document_version_id`);
- `category`: orçamento, referência de preço, evidência, documento, outro;
- `storage_bucket`, `storage_path`, nome original, MIME, tamanho e hash;
- descrição, status de antivírus/processamento;
- auditoria e exclusão lógica.

O caminho futuro no Storage deve incluir IDs não adivinháveis, por exemplo:

```text
organizations/{organization_id}/processes/{process_id}/{category}/{attachment_id}/{safe_filename}
```

O caminho organiza, mas não autoriza. A tabela e as políticas do bucket validam tenant e permissão. Downloads preferem URLs assinadas de curta duração. Upload deve validar tamanho, MIME, extensão, hash e, futuramente, antivírus.

## 11. Migração do estado local para Supabase

### Fase 1 — contratos de domínio no frontend

- mover tipos hoje espalhados por componentes para `src/domain`;
- separar estado de interface de estado persistente;
- introduzir IDs UUID no lugar de `Date.now()`/números locais;
- definir schemas Zod e enums canônicos;
- criar uma interface `ProcessRepository` sem alterar a aparência;
- manter `InMemoryProcessRepository` para desenvolvimento e testes.

### Fase 2 — autenticação e contexto organizacional

- configurar Supabase client apenas após aprovação do schema;
- implementar login real, sessão, carregamento de vínculos e seleção de organização;
- criar `AuthProvider` e `OrganizationProvider`;
- não permitir query de processo antes de haver tenant ativo autorizado.

### Fase 3 — núcleo do processo

- implementar organizações, departamentos, memberships/RBAC e RLS;
- implementar `procurement_processes`, demanda, participantes e itens;
- substituir o grande estado do `App` por carregamento/salvamento do processo;
- usar autosave com debounce, indicador explícito e tratamento de conflito.

### Fase 4 — documentos e versões

- persistir DFD e ETP primeiro;
- depois Matriz de Riscos e Pesquisa de Preços;
- por fim TR e ligações entre versões;
- cada vertical deve incluir RLS, auditoria, testes e migração de dados antes de avançar.

### Fase 5 — revisão e anexos

- executar as mesmas regras determinísticas em módulo compartilhado testável;
- persistir `review_runs` e `review_findings`;
- habilitar Storage somente após políticas e validação de upload.

Durante a transição, não manter dois estados independentes como fonte de verdade. O servidor retorna o agregado; o cliente mantém cache de edição e envia comandos/patches. Dados herdados no TR devem derivar de versões relacionadas, não de cópias soltas.

## 12. Riscos técnicos

| Risco | Consequência | Mitigação |
|---|---|---|
| Política RLS incompleta | vazamento entre órgãos | política deny-by-default, testes com dois tenants, revisão independente |
| `organization_id` divergente em filhos | associação cross-tenant | FKs compostas/triggers e testes de integridade |
| JSONB excessivo | relatórios e migrações difíceis | promover campos consultáveis; schemas versionados |
| Normalização excessiva | evolução lenta e queries complexas | documentos versionados híbridos, tabelas apenas para listas relevantes |
| Draft sobrescrito por outra sessão | perda de trabalho | controle de versão otimista e resolução de conflito |
| Aprovação de conteúdo mutável | perda de valor probatório | versões imutáveis e hash |
| Auditoria volumosa/sensível | custo e risco LGPD | política de retenção, diff seletivo e mascaramento |
| RBAC baseado só em nomes | autorização frágil | permissões atômicas e papéis configuráveis |
| JWT desatualizado | permissões antigas continuam válidas | validar memberships no banco; não depender apenas de claims |
| Cálculos diferentes entre cliente e servidor | estimativas inconsistentes | módulo compartilhado e cálculo canônico no backend/SQL futuramente |
| Autosave agressivo | excesso de escrita/auditoria | debounce, patch semântico e eventos agrupados |
| Arquivos maliciosos | incidente de segurança | validação, limites, quarentena e antivírus futuro |
| Migração direta do `App` monolítico | regressões no fluxo aprovado | repositório abstrato, testes e migração vertical incremental |

## 13. Ordem recomendada de implementação

1. Aprovar decisões abertas deste documento.
2. Extrair tipos/schemas e separar estado de UI, sem Supabase.
3. Escrever matriz de permissões e testes esperados de RLS.
4. Criar migrations de organizações, perfis, departamentos e memberships.
5. Criar RBAC extensível, seeds iniciais e políticas RLS.
6. Criar processos, participantes, demanda e itens.
7. Implementar autenticação/contexto de organização no frontend.
8. Conectar Demanda com repositório Supabase e auditoria.
9. Criar infraestrutura de documentos/versionamento.
10. Migrar DFD e ETP de forma vertical.
11. Migrar Matriz de Riscos e Pesquisa de Preços.
12. Migrar TR e dependências entre versões.
13. Persistir Revisão Inteligente determinística.
14. Implementar anexos/Storage depois das políticas.
15. Somente então implementar Aprovações completas e integrações/IA futuras.

## 14. Decisões que exigem aprovação antes do banco

1. **Estratégia híbrida:** aprovar documentos versionados em JSONB com listas importantes relacionais, em vez de uma tabela por formulário ou um JSON único para todo o processo.
2. **Unidade do tenant:** confirmar que organização é sempre a fronteira de isolamento; departamentos não são tenants independentes.
3. **Usuário multi-organização:** confirmar que o mesmo `auth.user` pode possuir vínculos e papéis diferentes em vários órgãos.
4. **Escopo departamental:** decidir se papéis podem ser limitados por departamento desde a primeira versão ou somente por organização.
5. **Numeração de processos:** definir formato, unicidade por organização/ano e quem pode reservar/cancelar números.
6. **Ciclo de aprovação/versionamento:** definir em que evento o draft é congelado e quais perfis podem criar nova versão após aprovação.
7. **Demanda versionada:** decidir se Demanda também precisa de versões imutáveis desde o início ou se auditoria detalhada é suficiente até sua formalização no DFD.
8. **Retenção de auditoria:** definir prazo, dados que podem aparecer em snapshots e requisitos legais/LGPD do órgão.
9. **Exclusão:** confirmar política de arquivamento versus exclusão definitiva de processos e documentos.
10. **Aprovação e assinatura:** esclarecer se aprovação futura é apenas decisão interna autenticada ou exigirá assinatura eletrônica integrada.
11. **CNPJ/CPF e dados pessoais:** classificar dados pessoais realmente necessários para definir mascaramento, acesso e retenção.
12. **Hospedagem e ambientes:** definir projeto Supabase por ambiente (`dev`, `staging`, `prod`) e requisitos de região, backup, recuperação e residência de dados.

As decisões foram aprovadas com estas definições: modelo híbrido relacional + JSONB; `organization_id` como fronteira; usuário multi-organização; RBAC organizacional e departamental; numeração por organização/ano; versões concluídas/aprovadas imutáveis; Demanda versionada; auditoria append-only; arquivamento lógico; aprovação separada de assinatura; classificação em público, interno, restrito e dado pessoal/sensível; ambientes separados; e RPCs seguras para operações críticas.

A primeira fundação está em `supabase/migrations/20260822210000_foundation.sql`. Ela não persiste ainda o conteúdo completo dos documentos e não foi aplicada a um banco nesta sessão.
