# Matriz técnica de homologação — Correio Eletrônico

Fonte: Termo de Referência/Edital de Deodápolis-MS, transcrito em `src/features/poc/deodapolisRequirements.ts`. Status inicial de todos os itens: **NÃO AVALIADO**.

## Controle

- 29 itens pertencentes à matriz vigente: 9 obrigatórios e 20 complementares.
- Obrigatórios: 4.4.2, 4.4.3, 4.4.4, 4.4.5, 4.4.18, 4.4.19, 4.4.21, 4.4.33 e 4.4.34.
- Resposta aceita: ATENDE, NÃO ATENDE, PARCIAL ou NÃO INFORMADO.
- “APTO TECNICAMENTE PARA TESTE” exige ATENDE com evidência nos 9 obrigatórios.

## Matriz oficial e pergunta de homologação

| ID | Tipo | Categoria | Responsável | Descrição oficial / pergunta objetiva | Evidência mínima |
|---|---|---|---|---|---|
| 4.4.1 | Complementar | DOMÍNIO | COMPARTILHADO | Disponibiliza contas em `@deodapolis.ms.gov.br` com 10, 25 e 50 GB conforme os quantitativos contratados? | Painel, proposta e demonstração de cotas |
| 4.4.2 | **Obrigatório** | WEBMAIL/IMAP/POP3/SMTP | FORNECEDOR_EMAIL | As contas permitem Webmail e clientes externos por IMAP, POP3 e SMTP? | Demonstração ao vivo dos quatro acessos |
| 4.4.3 | **Obrigatório** | WEBMAIL | FORNECEDOR_EMAIL | O Webmail possui interface em língua portuguesa? | Captura e demonstração ao vivo |
| 4.4.4 | **Obrigatório** | CAIXA POSTAL | FORNECEDOR_EMAIL | Envia e recebe anexos de no mínimo 37 MB, desconsiderando a codificação? | Mensagem de teste próxima a 37 MB |
| 4.4.5 | **Obrigatório** | CAIXA POSTAL | FORNECEDOR_EMAIL | Envia, recebe e armazena mensagens preservando a integridade durante toda a vigência? | Teste ponta a ponta e política de integridade |
| 4.4.6 | Complementar | ADMINISTRAÇÃO | FORNECEDOR_EMAIL | Permite listas de distribuição/grupos? | Criar grupo e testar entrega |
| 4.4.7 | Complementar | ADMINISTRAÇÃO | FORNECEDOR_EMAIL | Permite aliases vinculados às contas? | Criar alias e testar recebimento |
| 4.4.8 | Complementar | ADMINISTRAÇÃO | FORNECEDOR_EMAIL | Permite redirecionamento automático? | Configuração e teste ao vivo |
| 4.4.9 | Complementar | WEBMAIL | FORNECEDOR_EMAIL | Disponibiliza agenda individual de contatos? | Cadastro e consulta de contato |
| 4.4.10 | Complementar | WEBMAIL | FORNECEDOR_EMAIL | Pesquisa por remetente, destinatário, assunto, conteúdo, período e anexos? | Busca combinada ao vivo |
| 4.4.11 | Complementar | WEBMAIL | FORNECEDOR_EMAIL | Possui Entrada, Enviados, Rascunhos, Lixeira, Spam e Arquivo? | Inspeção visual das pastas |
| 4.4.12 | Complementar | WEBMAIL | FORNECEDOR_EMAIL | Permite pastas personalizadas? | Criar pasta e mover mensagem |
| 4.4.13 | Complementar | WEBMAIL | FORNECEDOR_EMAIL | Permite filtros automáticos? | Criar e executar filtro |
| 4.4.14 | Complementar | WEBMAIL | FORNECEDOR_EMAIL | Permite resposta automática de ausência? | Configurar e testar resposta |
| 4.4.15 | Complementar | WEBMAIL | FORNECEDOR_EMAIL | Permite assinatura personalizada por conta? | Configurar e enviar mensagem |
| 4.4.16 | Complementar | ANTISPAM | FORNECEDOR_EMAIL | Permite bloqueio e lista de remetentes confiáveis? | Configuração ao vivo |
| 4.4.18 | **Obrigatório** | TLS/SSL | COMPARTILHADO | A autenticação utiliza protocolos criptografados? | Configuração, certificado e inspeção da conexão |
| 4.4.19 | **Obrigatório** | IMAP | FORNECEDOR_EMAIL | Há sincronização entre Webmail e clientes de correio? | Alteração sincronizada ao vivo |
| 4.4.21 | **Obrigatório** | MIGRAÇÃO | COMPARTILHADO | Importa e exporta caixas em formato compatível com outras plataformas? | Exportação/importação real com pastas e anexos |
| 4.4.22 | Complementar | ADMINISTRAÇÃO | FORNECEDOR_EMAIL | Administrador redistribui armazenamento dentro do total contratado sem intervenção da contratada? | Operação no painel |
| 4.4.23 | Complementar | ADMINISTRAÇÃO | FORNECEDOR_EMAIL | Painel mostra espaço utilizado e disponível por conta? | Consulta ao vivo |
| 4.4.24 | Complementar | ADMINISTRAÇÃO | FORNECEDOR_EMAIL | Painel mostra contas contratadas, em uso e disponíveis? | Consulta ao vivo |
| 4.4.25 | Complementar | SEGURANÇA | FORNECEDOR_EMAIL | Registra logs das operações administrativas? | Operação e consulta do evento |
| 4.4.27 | Complementar | ADMINISTRAÇÃO | FORNECEDOR_EMAIL | Cria caixas compartilhadas com autenticação individual e sem compartilhar senhas? | Acesso por dois usuários |
| 4.4.29 | Complementar | SEGURANÇA | FORNECEDOR_EMAIL | Administrador define complexidade, comprimento, expiração e bloqueio de senha? | Configuração da política |
| 4.4.30 | Complementar | ADMINISTRAÇÃO | FORNECEDOR_EMAIL | Consulta entrega, rejeição, bloqueio e devolução sem ler o conteúdo? | Rastreamento ao vivo com privacidade |
| 4.4.31 | Complementar | BACKUP | FORNECEDOR_EMAIL | Recupera mensagens excluídas durante a retenção? | Exclusão e recuperação ao vivo |
| 4.4.33 | **Obrigatório** | SEGURANÇA | FORNECEDOR_EMAIL | Administrador bloqueia imediatamente conta comprometida preservando dados? | Bloqueio e verificação dos dados |
| 4.4.34 | **Obrigatório** | MIGRAÇÃO | COMPARTILHADO | Exporta em formato reconhecido preservando mensagens, anexos, datas, participantes e pastas? | Arquivo PST/MBOX/EML validado em outra solução |

## Divergências documentais

1. A redação recebida possui também 4.4.17, 4.4.20, 4.4.26, 4.4.28 e 4.4.32. A matriz vigente possui 29 itens e o total oficial informado é 94. Incluir os cinco elevaria o total para 99 e os complementares para 54. É necessária decisão documental.
2. Há referência a **1 conta de 50 GB** em parte do roteiro e a **11 contas de 50 GB** em outra parte do TR. Mantém-se, sem alteração contratual, o registro anterior 20×10 GB, 19×25 GB e 11×50 GB, marcado como “DIVERGÊNCIA DOCUMENTAL — REQUER CONFERÊNCIA”.
