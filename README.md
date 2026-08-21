# GOV TOTAL

Fundação de uma plataforma SaaS multi-tenant para órgãos da Administração Pública brasileira. O **Core GOV TOTAL** fornecerá identidade, organizações, autorização, processos, documentos, workflow e auditoria para verticais independentes. A primeira vertical planejada é o **GOV COMPRAS IA**, voltado à fase interna das contratações públicas.

> **Limite desta etapa:** este repositório contém somente a fundação técnica e a documentação arquitetural. DFD, ETP, pesquisa de preços, matriz de riscos, termo de referência, IA e dashboards completos ainda não foram implementados.

## Princípios do produto

- isolamento rigoroso entre organizações desde o banco;
- segurança e privacidade por padrão, com RBAC, RLS, auditoria e minimização de dados;
- IA estritamente assistiva: toda saída será identificada, revisável, editável e sujeita à aprovação humana;
- acessibilidade, responsividade e observabilidade;
- módulos desacoplados sobre um Core pequeno e reutilizável;
- migrations, testes e decisões arquiteturais versionados;
- adapters para reduzir acoplamento a Supabase e integrações futuras.

## Stack

- React 19, TypeScript estrito e Vite;
- Tailwind CSS;
- Vitest e Testing Library;
- ESLint;
- Supabase (PostgreSQL, Auth e Storage), integrado nas próximas etapas;
- PostgreSQL RLS como fronteira final de isolamento.

## Arquitetura

O frontend segue organização por domínio. `app` compõe providers e rotas; `core` contém capacidades transversais; `modules` contém verticais; `shared` mantém elementos sem regra de negócio; `infrastructure` concentra adapters de fornecedores.

```text
src/
├── app/                 # bootstrap, shell, providers e futuras rotas
├── core/                # contratos e capacidades reutilizáveis
│   ├── auth/
│   ├── organizations/
│   ├── permissions/
│   └── workflow/
├── modules/
│   └── compras/         # vertical futura GOV COMPRAS IA
├── infrastructure/      # adapters (Supabase, telemetria e integrações)
├── shared/              # UI, tipos, hooks e utilitários agnósticos
└── test/                # configuração e utilidades de testes
```

As decisões, o modelo relacional, a estratégia RLS, auditoria, riscos, divisão build-versus-buy e roadmap estão em [`docs/architecture.md`](docs/architecture.md). A migration inicial proposta está em [`supabase/migrations`](supabase/migrations).

## Começando

Requisitos: Node.js 22+ e npm 10+.

```bash
npm install
cp .env.example .env.local
npm run dev
```

As variáveis `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` são públicas por definição e só devem usar a chave publicável/anon. A `service_role` nunca pode ser enviada ao navegador.

## Comandos

| Comando | Finalidade |
| --- | --- |
| `npm run dev` | servidor de desenvolvimento |
| `npm run build` | typecheck e build de produção |
| `npm run lint` | análise estática |
| `npm run typecheck` | validação TypeScript sem emissão |
| `npm test` | testes unitários uma vez |
| `npm run test:watch` | testes em modo watch |

## Estado atual e próximos passos

A página inicial apenas comunica o escopo da fundação; ela não simula funcionalidades nem dados. A próxima etapa recomendada é validar os ADRs e o modelo de ameaças, iniciar o Supabase local, testar as políticas RLS da migration e só então implementar autenticação e seleção segura de organização.

Consulte também as regras permanentes em [`AGENTS.md`](AGENTS.md). Não avance para módulos funcionais sem aprovação explícita.
