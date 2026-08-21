# AGENTS.md — GOV TOTAL

Estas regras valem para todo o repositório.

## Princípios obrigatórios

- Trate isolamento multi-tenant, segurança, LGPD e acessibilidade como requisitos, não melhorias opcionais.
- Toda tabela de negócio deve possuir `organization_id`, chave estrangeira e políticas RLS. Exceções globais devem ser documentadas.
- Nunca confie em `organization_id`, role ou permissões enviados pelo cliente; autorize no banco e no servidor.
- IA é somente assistiva: saída deve ser identificada, editável, revisável e aprovada por uma pessoa. Nunca automatize decisão administrativa.
- Não registre segredos, tokens, dados pessoais, conteúdo integral de documentos ou prompts sensíveis em logs.
- Não crie telas ou fluxos com dados falsos apresentados como reais.
- Prefira módulos pequenos, tipados e testáveis; evite abstrações prematuras e dependência direta de fornecedores fora da camada de infraestrutura.

## Qualidade

- Use TypeScript em modo estrito; não introduza `any` sem justificativa explícita.
- Componentes React usam nomes em `PascalCase`; hooks usam prefixo `use`; arquivos utilitários usam `kebab-case`.
- Garanta estados de carregamento, vazio, erro e sucesso nas interfaces conectadas a dados.
- Preserve navegação por teclado, foco visível, HTML semântico, contraste e rótulos acessíveis.
- Toda mudança de comportamento deve incluir testes proporcionais ao risco.
- Rode antes de concluir: `npm run lint`, `npm run typecheck`, `npm test` e `npm run build`.

## Banco e segurança

- Mudanças de banco são migrations SQL versionadas; migrations aplicadas não são reescritas.
- RLS deve estar habilitado e forçado em tabelas multi-tenant. Novas políticas precisam de testes de isolamento positivo e negativo.
- Funções `security definer` devem fixar `search_path`, validar autorização e ter privilégios mínimos.
- Auditoria é append-only. Eventos devem guardar ator, tenant, ação, alvo, data e metadados mínimos, sem conteúdo sensível.
- Use UUIDs e timestamps `timestamptz` em UTC.

## Dependências e configuração

- Não exponha chaves de serviço no frontend. Variáveis públicas do Vite usam apenas credenciais publicáveis.
- Dependências novas exigem propósito claro, manutenção ativa e avaliação de lock-in/licença.
- Integrações externas devem ser acessadas por adapters/ports, com timeout, retry controlado e idempotência.

## Commits e documentação

- Não misture refatorações não relacionadas.
- Atualize README, ADRs e documentação de dados quando decisões públicas mudarem.
- Commits devem ser objetivos e descrever o resultado da mudança.
