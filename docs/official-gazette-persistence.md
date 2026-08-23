# Diário Oficial persistente — configuração da POC

Os requisitos 4.3.1 e 4.3.12 permanecem **EM DESENVOLVIMENTO** até esta configuração ser aplicada e o comportamento ser observado no ambiente público.

## Configuração externa necessária

1. Criar ou selecionar um projeto Supabase exclusivo de staging/demo. Não usar produção.
2. Aplicar as migrations versionadas, incluindo `20260823075524_official_gazette_persistence.sql`.
3. Criar uma organização DEMO, usuário autenticado, vínculo ativo e papel com:
   - `gazette.read`;
   - `gazette.manage`;
   - `gazette.publish`;
   - `audit.read` para consulta administrativa da trilha.
4. Configurar no Cloudflare Pages:
   - `VITE_SUPABASE_URL`;
   - `VITE_SUPABASE_PUBLISHABLE_KEY` (preferencial) ou `VITE_SUPABASE_ANON_KEY` legado.
   - `VITE_GOV_TOTAL_ORGANIZATION_ID`, com o UUID da organização DEMO cujo acervo será exibido.
5. Gerar novo deploy da branch `main` depois de configurar as variáveis.
6. Confirmar no Acervo o selo **ACERVO PERSISTENTE · SUPABASE**.

Somente URL e chave pública/publishable entram no frontend. `service_role`, secret key, senha do banco e tokens administrativos nunca podem usar prefixo `VITE_` nem ser enviados ao Cloudflare Pages como variáveis do cliente.

## Roteiro 4.3.1 — preservação permanente

1. Publicar uma edição usando uma sessão administrativa autorizada.
2. Registrar número, URL permanente, data/hora e hashes exibidos.
3. Recarregar o navegador e localizar novamente a edição.
4. Tentar update/delete direto com um usuário comum e registrar o bloqueio.
5. Criar retificação em nova edição, mantendo a anterior acessível.

Evidência: capturas do acervo antes/depois da recarga, URL da edição antiga, hash, resultado do bloqueio e evento de auditoria.

## Roteiro 4.3.12 — acervo definitivo e consultável

1. Abrir o acervo persistente.
2. Filtrar por número e data.
3. Abrir uma edição antiga e consultar seu conteúdo integral.
4. Baixar o arquivo eletrônico associado.
5. Recarregar a aplicação e repetir a consulta.

Evidência: URL pública, data/hora, filtros utilizados, captura da edição aberta, nome/tamanho/hash do arquivo e resultado após recarga.

## Critério de promoção

Somente promover os requisitos para **PRONTO PARA TESTE** depois que migration, credenciais públicas, autenticação administrativa e ao menos uma publicação persistente estiverem funcionais no ambiente de demonstração. O registro formal na Central de Evidências continua sendo necessário; nenhum teste altera automaticamente para **COMPROVADO NA POC**.
