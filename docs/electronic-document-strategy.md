# Estratégia futura — documento eletrônico do Diário Oficial

## Estado atual

O frontend oferece pré-visualização HTML e `window.print()`. Isso permite imprimir ou usar “Salvar como PDF” do navegador, mas **não constitui gerador próprio de PDF**, não estabiliza os bytes do documento e não garante paginação idêntica entre navegadores.

Por isso, 4.3.13 e 4.3.31 permanecem **EM DESENVOLVIMENTO**.

## Requisitos do artefato futuro

- cabeçalho e rodapé parametrizados;
- identificação e metadados da edição;
- sumário e conteúdo integral dos atos;
- fontes incorporadas;
- quebra e numeração de páginas determinísticas;
- arquivo próprio para download;
- conteúdo textual pesquisável;
- hash estável para assinatura e auditoria;
- acessibilidade do documento, quando aplicável.

## Alternativas recomendadas para avaliação posterior

### Playwright/Puppeteer em backend

Renderiza HTML/CSS em Chromium controlado e gera PDF. Impacto aproximado: pacote e navegador podem consumir centenas de MB. Não é adequado ao modo low-disk atual. Exige serviço backend, fila, limites de execução e testes de determinismo.

### PDFKit

Geração programática em Node. Pacote base costuma ser relativamente menor que um navegador, mas layout, sumário, quebras, fontes e acessibilidade exigem implementação própria considerável. O impacto real aumenta com fontes e recursos auxiliares.

### pdf-lib

Útil para criar e modificar PDFs, porém paginação e diagramação complexas precisam ser construídas manualmente. Não resolve sozinho o layout do Diário.

Os tamanhos devem ser medidos no ambiente escolhido antes da adoção; não foi feito download neste ciclo.

## Implementação recomendada

1. Definir formato canônico e critérios de aceite.
2. Criar serviço de geração no backend, sem expor operação crítica ao frontend.
3. Congelar versão da edição e gerar o arquivo.
4. Validar texto, sumário, páginas e rodapé automaticamente.
5. Calcular hash e integrar assinatura ICP-Brasil.
6. Armazenar arquivo e metadados em storage definitivo.
7. Disponibilizar URL imutável e download público.

## Critério para promoção

4.3.13 somente pode avançar após existir arquivo eletrônico próprio reproduzível e baixável. 4.3.31 somente pode avançar após a numeração ser validada em documentos com uma e várias páginas, incluindo quebras complexas.
