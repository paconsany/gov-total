# Documento eletrônico do Diário Oficial

## Implementação atual

O GOV TOTAL gera um arquivo eletrônico próprio em **HTML autocontido**, textual e baixável. O arquivo contém identificação municipal, edição, data, tipo, sumário e conteúdo integral dos atos.

A composição é determinística:

- página 1: identificação e sumário;
- páginas seguintes: um ato por página;
- rodapé em todas as páginas com “Página X de Y”;
- nome estável no formato `diario-AAAA-NNNNNN.html`;
- CSS A4 incorporado no próprio documento.

Isso permite testar 4.3.13 e 4.3.31 sem afirmar que existe PDF próprio. Ambos estão **PRONTOS PARA TESTE**, sujeitos à aceitação do formato eletrônico HTML no roteiro oficial.

## Roteiro de demonstração

1. Abrir Portal Público → Diário Oficial.
2. Abrir uma edição publicada.
3. Conferir visualização no navegador e páginas numeradas.
4. Acionar “Baixar arquivo eletrônico HTML”.
5. Abrir o arquivo baixado sem depender da aplicação.
6. Confirmar identificação, sumário, atos, texto pesquisável e sequência Página X de Y.
7. Registrar arquivo, captura e resultado no sistema de evidências.

## Limites explícitos

- Não é PDF.
- `window.print()` continua sendo apenas impressão/salvamento do navegador.
- O arquivo ainda não possui assinatura ICP-Brasil.
- A permanência definitiva ainda depende de backend/storage.

## Evolução futura

Caso o edital ou a comissão exija PDF canônico, avaliar Playwright/Puppeteer, PDFKit ou pdf-lib em serviço backend. Um navegador empacotado pode consumir centenas de MB; PDFKit/pdf-lib exigem diagramação própria. Nenhuma dependência foi instalada neste ciclo.
