# Checklist de staging — POC Deodápolis

Este checklist prepara os requisitos 4.1.11 e 4.1.30. Documentação não altera o status atual.

## Ambiente-alvo

- URL proposta: `https://poc-deodapolis.govtotal.com.br` — confirmar domínio antes de publicar.
- Não utilizar produção nem dados reais.
- Certificado emitido por autoridade publicamente confiável, dentro da validade e cobrindo o hostname.

## 4.1.11 — HTTPS / SSL-TLS válido

| Verificação | Procedimento | Evidência | PASSOU | FALHOU |
|---|---|---|---|---|
| URL HTTPS | Abrir a URL no Chrome e Edge | Captura da barra e URL | Carrega sem alerta | Qualquer alerta TLS |
| Cadeia TLS | Inspecionar certificado, emissor, validade e hostname | Exportação/captura dos detalhes | Cadeia válida e hostname correto | Cadeia, validade ou hostname inválido |
| Redirecionamento | Abrir a mesma URL usando `http://` | Registro do redirecionamento | Resposta redireciona para HTTPS | Conteúdo permanece em HTTP |
| Mixed content | Abrir DevTools → Console/Network e recarregar | Captura sem alertas | Nenhum recurso inseguro | Qualquer recurso HTTP ativo |

## 4.1.30 — comunicações exclusivamente criptografadas

1. Abrir DevTools → Network.
2. Limpar o histórico e percorrer Portal, Diário e POC.
3. Confirmar que todas as requisições usam HTTPS/WSS.
4. Confirmar que nenhuma credencial, token ou dado pessoal aparece em URL.
5. Executar teste externo de configuração TLS quando a rede permitir.

Evidências: arquivo HAR sanitizado, capturas do Network, resultado do teste TLS e identificação da versão publicada.

Critério PASSOU: nenhuma comunicação HTTP/WS, certificado válido e nenhum mixed content. Qualquer exceção resulta em FALHOU.

## Estado

Os dois requisitos permanecem **EM DESENVOLVIMENTO** até execução em staging real.
