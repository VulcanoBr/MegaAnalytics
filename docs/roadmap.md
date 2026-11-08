# Roadmap

## Fases concluídas

| Fase | Entrega |
| --- | --- |
| 1. Infraestrutura de dados | Tabelas `draws` e `import_batches` com restrições; importação incremental de XLSX com SHA-256, rejeição de divergências e lacunas, auditoria por lote; `HistoricalValidator`; telas de envio e histórico de importações |
| 2. Dashboard estatístico | Indicadores gerais, frequência das dezenas (mapa de calor e rankings), maior atraso, comparativo entre períodos, pares/ímpares, soma e evolução histórica |
| 3. Análise combinatória | Pares e ternos mais frequentes (com filtro por dezena) e repetição de dezenas entre concursos consecutivos |
| 4. Distribuições | Dezenas consecutivas no mesmo concurso e distribuição por faixas numéricas, com valores esperados exatos |
| 5. Concursos, relatórios e exportação | Consulta e detalhe de concursos, relatório por período, impressão/PDF e exportação CSV |

Com isso, todos os módulos da especificação original estão implementados: importação, validação, análises estatísticas, dashboard, relatórios e exploração dos dados.

## Ideias para o futuro

Sugestões que **não** fazem parte da especificação original:

- **Autenticação** (por exemplo, nativa do Rails) para proteger o upload e as telas.
- **Cache** das análises por `Draw.maximum(:contest_number)`.
- **Importação automática** do arquivo oficial, agendada em segundo plano.
- **Exportação em XLSX** (por exemplo, com a gem `caxlsx`).
- **Gráficos interativos** (Chart.js via Stimulus) como alternativa aos gráficos em SVG.
- **Documentação de API** caso os dados passem a ser expostos em JSON.
- **Integração contínua** (GitHub Actions) executando `bin/rails test`.

Sugestões e contribuições são bem-vindas; consulte o [README](../README.md#contribuindo).
