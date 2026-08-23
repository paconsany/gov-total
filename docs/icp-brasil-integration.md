# Levantamento técnico — assinatura ICP-Brasil

## Requisito

O requisito 4.3.4 exige assinatura digital ICP-Brasil. Ele permanece **EM DESENVOLVIMENTO**.

## Ponto do fluxo

1. A edição fica pronta para publicação e imutável para conteúdo.
2. O sistema gera o documento eletrônico canônico.
3. O responsável inicia a assinatura.
4. O serviço/certificado ICP-Brasil assina o documento.
5. O GOV TOTAL valida assinatura, cadeia, carimbo temporal e integridade.
6. Somente o documento validado pode ser publicado no acervo definitivo.

## Documento assinado

Arquivo eletrônico canônico da edição, com número, ano, data, tipo, identificação municipal, sumário, atos, anexos referenciados, cabeçalho, rodapé e paginação estabilizada. O formato final ainda depende da decisão sobre o motor de documentos.

## Responsabilidades do GOV TOTAL

- produzir bytes canônicos e hash antes da assinatura;
- controlar versão e imutabilidade;
- integrar o provedor por backend/RPC seguro;
- armazenar documento, assinatura, cadeia e metadados;
- validar retorno e impedir publicação em caso de falha;
- exibir validação pública sem expor segredo ou chave privada;
- registrar eventos técnicos e responsáveis.

## Dependências externas

- certificado ICP-Brasil válido e política de uso;
- serviço de assinatura ou componente homologado;
- carimbo do tempo quando exigido;
- ambiente HTTPS;
- backend e storage definitivo;
- definição de custódia, revogação e renovação.

## Evidência necessária na POC

- documento assinado de teste;
- verificação por ferramenta independente;
- cadeia válida, signatário, data/hora e integridade;
- tentativa de alteração posterior invalidando a assinatura;
- trilha do fluxo sem acesso do frontend à chave privada.

Nenhuma assinatura, selo ou certificado fictício deve ser exibido como válido.
