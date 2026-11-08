## [← Voltar ao README](../README.md)

---

# Guia de uso

Tela a tela, com os parâmetros de URL aceitos. Todos os parâmetros são opcionais; valores inválidos são ignorados e o padrão é usado. O significado de cada indicador está em [analises-estatisticas.md](analises-estatisticas.md).

O menu superior dá acesso a: **Dashboard**, **Concursos**, **Combinações**, **Distribuições**, **Relatório** e **Importações**.

Enquanto não houver concursos cadastrados, as telas de análise exibem um aviso com o atalho para a primeira importação.

## Dashboard

`/` ou `/dashboard`

| O que mostra       | Detalhe                                                                                    |
| ------------------ | ------------------------------------------------------------------------------------------ |
| Indicadores gerais | Total de concursos, primeiro e último sorteio, período analisado, soma média e mediana     |
| Mapa de calor      | As 60 dezenas coloridas pela frequência; ao passar o mouse, mostra vezes e % dos concursos |
| Rankings           | Mais sorteadas, menos sorteadas e maior tempo sem sair                                     |
| Comparativo        | (apenas nas janelas 50/100/500) dezenas mais acima e abaixo da média histórica             |
| Distribuições      | Pares e ímpares; soma das dezenas em faixas de 20                                          |
| Evolução histórica | Gráfico de linhas da frequência de uma dezena por blocos de concursos                      |

| Parâmetro | Valores                         | Padrão                |
| --------- | ------------------------------- | --------------------- |
| `window`  | `50`, `100`, `500`, `all`       | `all`                 |
| `number`  | `1` a `60` (dezena da evolução) | dezena mais frequente |
| `block`   | `50`, `100`, `200`, `500`       | `100`                 |

Exemplo: `/dashboard?window=100&number=10&block=50`

## Concursos

`/draws` e `/draws/:número`

### Lista

Tabela com concurso, data, dezenas, soma, ganhadores da Sena, prêmio e arrecadação, com paginação.

| Parâmetro    | Valores                                    | Padrão                          |
| ------------ | ------------------------------------------ | ------------------------------- |
| `from`, `to` | datas ISO (`aaaa-mm-dd`), inclusivas       | sem limite                      |
| `number`     | `1` a `60` (concursos que contêm a dezena) | todas                           |
| `order`      | `desc`, `asc`                              | `desc` (mais recentes primeiro) |
| `per`        | `25`, `50`, `100`                          | `25`                            |
| `page`       | número da página                           | `1`                             |
| `contest`    | nº do concurso: redireciona para o detalhe | —                               |

Se `from` for posterior a `to`, a tela exibe um aviso e nenhum resultado. Um número de página além do fim usa a última página.

Exemplo: `/draws?from=2026-01-01&to=2026-06-30&number=10`

### Detalhe

Mostra as dezenas sorteadas; soma; pares e ímpares; sequências de dezenas consecutivas; dezenas repetidas do concurso anterior; dezenas por faixa; tabela de premiação (Sena, Quina e Quadra, com ganhadores e prêmio por ganhador); cidade/UF; arrecadação; acumulado; estimativa do próximo prêmio; acumulado do sorteio especial; observação; e link para o lote de importação que inseriu o concurso. Há botões para o concurso anterior e o próximo.

Concurso inexistente redireciona para a lista com um aviso.

## Combinações

`/combinations`

| Seção                                  | O que mostra                                                                                                                            |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Pares e ternos                         | Rankings com vezes, % dos concursos, quantas vezes acima do esperado e último concurso; totais de combinações possíveis × já ocorridas  |
| Repetição entre concursos consecutivos | Média de dezenas repetidas, distribuição observada × esperada, dezenas que mais se repetiram no concurso seguinte e repetições recentes |

| Parâmetro | Valores                                              | Padrão |
| --------- | ---------------------------------------------------- | ------ |
| `window`  | `50`, `100`, `500`, `all`                            | `all`  |
| `number`  | `1` a `60` (somente combinações que contêm a dezena) | todas  |
| `limit`   | `10`, `20`, `50`                                     | `20`   |

## Distribuições

`/distributions`

| Seção                | O que mostra                                                                                                                                                         |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Dezenas consecutivas | % de concursos com sequência, média de pares consecutivos, maior sequência, distribuição observada × esperada, pares `n–(n+1)` mais frequentes e sequências recentes |
| Faixas numéricas     | Por faixa de 10: dezenas sorteadas, % do total, média por concurso e concursos sem dezena na faixa; perfil de distribuição por faixas (observado × esperado)         |

Parâmetro: `window` (`50`, `100`, `500`, `all`; padrão `all`).

## Relatório por período

`/report`

Reúne em uma única página as análises do período escolhido: resumo (concursos, datas, arrecadação, prêmios pagos, concursos com ganhador × acumulados, maior prêmio e maior acumulado), frequência completa das 60 dezenas, pares e ímpares, soma, faixas, consecutivas, repetição e os 10 pares e ternos mais frequentes.

| Parâmetro    | Valores               | Padrão           |
| ------------ | --------------------- | ---------------- |
| `from`, `to` | datas ISO, inclusivas | todo o histórico |

Há atalhos de período: _Todo o histórico_, _Últimos 12 meses_, _Este ano_, _Ano passado_ e _Últimos 5 anos_.

**Imprimir / PDF:** o botão abre o diálogo de impressão do navegador; escolha "Salvar como PDF" para gerar um arquivo. Menus e filtros são ocultados na impressão.

Exemplo: `/report?from=2025-01-01&to=2025-12-31`

## Exportação CSV

Os arquivos seguem o padrão do Excel em português: separador `;`, vírgula como separador decimal, datas `dd/mm/aaaa` e codificação UTF-8 com BOM (os acentos abrem corretamente no Excel).

| Endereço                        | Conteúdo                      | Filtros aplicados               |
| ------------------------------- | ----------------------------- | ------------------------------- |
| `/draws.csv`                    | Todos os campos dos concursos | `from`, `to`, `number`, `order` |
| `/report.csv?section=frequency` | Frequência das 60 dezenas     | `from`, `to`                    |
| `/report.csv?section=pairs`     | 100 pares mais frequentes     | `from`, `to`                    |
| `/report.csv?section=triples`   | 100 ternos mais frequentes    | `from`, `to`                    |

O nome do arquivo inclui o filtro aplicado, por exemplo `megasena_concursos_de-2025-01-01_ate-2025-12-31.csv`. Uma `section` inválida redireciona para o relatório com um aviso.

## Importações

`/import_batches`

- **Lista:** total de concursos, primeiro e último sorteio, e as 50 importações mais recentes com status, linhas lidas, inseridas, ignoradas, erros e resultado da auditoria.
- **Nova importação:** envio de arquivo `.xlsx`.
- **Detalhe do lote:** nome e SHA-256 do arquivo, status, duração, contadores, erros e divergências (JSON) e relatório completo da validação histórica.

Veja [importacao.md](importacao.md) para as regras e mensagens.

---

## [← Voltar ao README](../README.md)

---
