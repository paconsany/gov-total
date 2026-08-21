# Arquitetura inicial do GOV TOTAL

## 1. Decisões arquiteturais

1. **Monólito modular primeiro.** Um frontend e um banco PostgreSQL, com limites por domínio. Reduz custo operacional sem impedir extração futura de módulos.
2. **PostgreSQL é a fonte de verdade.** Regras críticas de integridade, pertencimento ao tenant e autorização ficam no banco; o cliente nunca é fronteira de segurança.
3. **Tenant explícito por linha.** Entidades de negócio carregam `organization_id`. Chaves estrangeiras compostas impedem referências acidentais entre tenants.
4. **Autorização híbrida RBAC + escopo.** Roles agrupam permissões; atribuições têm escopo de organização e, futuramente, departamento/processo. RLS aplica a autorização mínima no dado.
5. **Workflow configurável, não um motor genérico irrestrito.** Definições versionadas descrevem estados e transições permitidas; comandos transacionais executam transições e auditam o resultado.
6. **Documentos imutáveis por versão.** Metadado lógico aponta para versões; objetos no Storage usam caminhos não adivinháveis e buckets privados. Aprovação referencia uma versão exata.
7. **Auditoria append-only.** Eventos relevantes são gravados no mesmo commit da mudança. Observabilidade técnica e trilha administrativa são conceitos separados.
8. **Integrações por ports/adapters.** Domínio depende de contratos internos, não dos SDKs de Supabase, PNCP, e-mail ou provedores de IA.
9. **IA assistiva e isolada.** Chamadas futuras passam por backend, minimizam dados, registram modelo/finalidade e produzem rascunhos. Publicar/aprovar sempre exige ação humana autorizada.

## 2. Contextos e módulos

### Core

- **Identity & Tenancy:** organizações, departamentos, membros e convites.
- **Access Control:** roles, permissões e atribuições.
- **Process Management:** processos, responsáveis, prazos e comentários.
- **Workflow:** definições versionadas, instâncias, tarefas e decisões humanas.
- **Documents:** documentos, versões, metadados e referências ao Storage.
- **Notifications:** preferências, outbox e entregas.
- **Audit:** trilha imutável e exportável.
- **Integrations:** credenciais cifradas no servidor, jobs, idempotência e estado de sincronização.
- **AI Governance:** futuramente, solicitações, rascunhos, proveniência, revisão e aprovação.

### Verticais

Cada vertical registra seus tipos de processo/documento, permissões e configurações, mas reutiliza IDs e serviços do Core. `GOV COMPRAS IA` terá schema lógico/módulo próprio e referenciará `core.processes`; não duplicará usuários, arquivos, auditoria ou workflow. Eventos de domínio e uma outbox transacional permitem projeções e integrações sem chamadas distribuídas dentro da transação principal.

## 3. Modelo de dados proposto

### Tenancy e acesso

- `organizations` 1—N `departments` e 1—N `organization_members`.
- `auth.users` 1—N `organization_members`; a identidade é global, a associação é por tenant.
- `roles` N—N `permissions` por `role_permissions`.
- `organization_members` N—N `roles` por `member_roles`.
- Roles de sistema podem servir como templates; atribuições e qualquer customização permanecem no tenant.

### Operação

- `processes` pertence a organização e opcionalmente departamento; `process_type` identifica a vertical.
- `workflow_definitions` possui versões; `workflow_instances` fixa uma versão para cada processo; tarefas e transições preservam histórico.
- `documents` 1—N `document_versions`; uma versão contém hash, MIME, tamanho, autor e `storage_key`.
- `comments` referencia um processo e, opcionalmente, documento; edição preserva histórico ou gera revisão auditável.
- `deadlines` referencia processo/tarefa e responsável.
- `notifications` são criadas por uma outbox idempotente e entregues por canais configurados.
- `integration_connections` e `integration_jobs` não expõem segredos ao frontend.
- `audit_events` registra ator, tenant, ação, recurso, correlação, origem e diferenças sanitizadas.

### GOV COMPRAS IA (etapa futura)

`procurement_cases` será uma extensão 1—1 de `processes`. DFD, ETP, pesquisa, matriz e TR serão artefatos distintos, versionados e vinculados ao caso. O encadeamento é regulado pelo workflow, não por atualização livre de status. Resultados de IA serão rascunhos separados da versão oficial.

## 4. RBAC inicial

Permissões são ações granulares no formato `recurso.ação`, por exemplo: `process.read`, `process.create`, `process.update`, `process.approve`, `document.read`, `document.manage`, `member.manage`, `role.manage`, `audit.read` e `integration.manage`.

Roles iniciais são templates, não regras codificadas no frontend:

| Role | Escopo resumido |
| --- | --- |
| `organization_admin` | configuração e membros do tenant; sem decisão administrativa implícita |
| `process_manager` | cria, atribui e movimenta processos conforme workflow |
| `author` | elabora artefatos e novas versões |
| `reviewer` | comenta e solicita ajustes |
| `approver` | aprova/rejeita etapas explicitamente atribuídas |
| `auditor` | leitura de processos e auditoria, sem alteração |
| `viewer` | leitura mínima autorizada |

Segregação de funções será uma restrição adicional: quem redige não ganha aprovação automaticamente. Permissão habilita uma ação; contexto, atribuição e estado do workflow ainda precisam autorizá-la.

## 5. Estratégia RLS no Supabase

- RLS habilitado e forçado em toda tabela do tenant, inclusive tabelas de junção e auditoria.
- O tenant ativo **não** virá de claim mutável nem de header confiado. A política confirma `auth.uid()` em `organization_members` ativo para o `organization_id` da própria linha.
- Leitura exige associação e permissão quando aplicável; escrita repete validações em `USING` e `WITH CHECK`.
- Operações complexas (convites, transições, aprovações) usam funções transacionais estreitas, com `security definer`, `search_path` fixo e grants mínimos.
- Foreign keys compostas `(organization_id, id)` garantem que relações permaneçam no mesmo tenant.
- Storage usa bucket privado e políticas derivadas do primeiro segmento do caminho, validado contra membership. URLs são temporárias.
- Service role fica somente em workers confiáveis; cada job recebe tenant explícito, valida o escopo e produz auditoria.
- Testes automatizados cobrirão usuário do tenant A, usuário do tenant B, usuário sem associação, associação suspensa e service worker.

A migration incluída implementa apenas a base de tenancy/RBAC e políticas conservadoras; não é considerada pronta para produção sem testes locais de RLS e revisão de segurança.

## 6. Auditoria

`audit_events` será particionável por data e append-only. Campos: `id`, `organization_id`, `occurred_at`, `actor_user_id`, `actor_type`, `action`, `resource_type`, `resource_id`, `request_id`, `correlation_id`, `ip_hash`, `user_agent`, `before`, `after` e `metadata` sanitizados.

- INSERT ocorre na mesma transação da mutação, preferencialmente por função de domínio/trigger específico.
- Clientes têm somente leitura quando possuem `audit.read`; nenhum cliente atualiza ou exclui eventos.
- Retenção é configurada conforme obrigação legal e política do órgão; expurgo autorizado também gera evidência fora da partição removida.
- Valores sensíveis, corpo de documento, tokens e prompts não entram no log. Dados pessoais são minimizados/pseudonimizados.
- Hash encadeado ou exportação WORM pode ser adicionado quando houver requisito formal de não repúdio; não será prometido antes disso.

## 7. Interno versus serviços externos

**Desenvolver internamente:** domínio de contratação, modelo multi-tenant, autorização contextual, workflow administrativo, versionamento/metadados, auditoria, adapters, governança da IA e regras de retenção.

**Usar serviços com adapters:** Supabase para PostgreSQL/Auth/Storage; provedor de e-mail/SMS; monitoramento de erros; processamento antivírus; OCR/extração; assinatura eletrônica qualificada; modelos de IA; fontes públicas como PNCP. Contratos, exportação e fallback devem evitar lock-in. Decisões legais e administrativas nunca são terceirizadas a modelos.

## 8. Riscos e controles

| Risco | Controle inicial |
| --- | --- |
| vazamento entre tenants | RLS deny-by-default, FK composta, testes negativos e revisão de policies |
| elevação de privilégio | autorização no banco, grants mínimos, sem confiar no JWT/UI |
| IDOR e URLs de arquivos | UUID, bucket privado, policies e URLs curtas assinadas |
| falha de segregação de funções | atribuição contextual e regra explícita no workflow |
| perda/alteração de histórico | versões imutáveis, auditoria transacional e backup testado |
| LGPD e dados em logs/IA | minimização, base/finalidade registradas, retenção e redaction |
| prompt injection/alucinação | fontes delimitadas, saída como rascunho, proveniência e revisão humana |
| supply chain | lockfile, atualização controlada, análise de dependências e CSP futura |
| indisponibilidade/limites externos | outbox, idempotência, retry com backoff, circuit breaker e reconciliação |
| complexidade prematura | monólito modular, ADRs e extração apenas mediante métricas |

## 9. Roadmap incremental

1. **Fundação (esta etapa):** documentação, shell React, qualidade, teste básico e migration proposta.
2. **Segurança local:** Supabase local, threat model, testes RLS, seeds mínimos e CI.
3. **Identidade e tenant:** login, convite, associação, seleção de organização e administração mínima.
4. **RBAC e auditoria:** autorização ponta a ponta, gestão de roles, eventos append-only e exportação.
5. **Processos e documentos:** CRUD real, Storage privado, versionamento, comentários e prazos.
6. **Workflow e notificações:** definições versionadas, tarefas/aprovação humana e outbox.
7. **Vertical Compras:** necessidade/DFD primeiro; evoluir artefato por artefato após validação com usuários.
8. **IA assistiva e integrações:** somente após governança, avaliação, consentimentos e controles operacionais.

## 10. Próximos cinco passos

1. Revisar esta arquitetura com especialistas em contratação pública, segurança e proteção de dados.
2. Criar threat model e matriz de classificação/retenção de dados.
3. Subir Supabase local e escrever testes de isolamento para cada policy da migration.
4. Definir ADRs de tenancy, autorização, documentos e auditoria, com critérios de aceite.
5. Implementar autenticação e associação ao tenant sem iniciar ainda os artefatos do GOV COMPRAS IA.
