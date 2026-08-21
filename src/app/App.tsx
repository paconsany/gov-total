const foundations = [
  'Multi-tenancy e RLS desde o banco',
  'RBAC, auditoria e LGPD por padrão',
  'Módulos desacoplados sobre um Core comum',
  'IA assistiva, sempre sob revisão humana',
]

export function App() {
  return (
    <main className="min-h-screen bg-slate-950 text-slate-100">
      <section className="mx-auto flex min-h-screen max-w-6xl flex-col justify-center px-6 py-16 lg:px-8">
        <p className="mb-4 text-sm font-semibold uppercase tracking-[0.22em] text-emerald-300">
          Fundação tecnológica
        </p>
        <h1 className="max-w-4xl text-5xl font-bold tracking-tight sm:text-7xl">
          GOV <span className="text-emerald-400">TOTAL</span>
        </h1>
        <p className="mt-6 max-w-3xl text-lg leading-8 text-slate-300 sm:text-xl">
          Core SaaS seguro e reutilizável para órgãos públicos brasileiros. A base
          para processos digitais auditáveis e para a futura vertical GOV COMPRAS IA.
        </p>

        <ul className="mt-12 grid gap-4 sm:grid-cols-2" aria-label="Princípios da fundação">
          {foundations.map((foundation) => (
            <li
              className="rounded-xl border border-slate-800 bg-slate-900/70 p-5 text-slate-200"
              key={foundation}
            >
              <span aria-hidden="true" className="mr-3 text-emerald-400">✓</span>
              {foundation}
            </li>
          ))}
        </ul>

        <aside className="mt-10 rounded-xl border border-amber-300/30 bg-amber-200/10 p-5 text-amber-100">
          <h2 className="font-semibold">Escopo atual</h2>
          <p className="mt-1 text-sm leading-6 text-amber-50/80">
            Esta etapa entrega apenas a fundação revisável. Nenhum documento,
            decisão administrativa ou conteúdo de IA é gerado por esta aplicação.
          </p>
        </aside>
      </section>
    </main>
  )
}
