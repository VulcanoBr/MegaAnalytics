## [← Voltar ao README](../README.md)

---

# Guia de desenvolvimento

## Ambiente

O ambiente principal de desenvolvimento usa **Windows + WSL2 + Ubuntu**, com Ruby, Rails e PostgreSQL instalados no Ubuntu. Qualquer ambiente Linux/macOS com Ruby 3.2+ e PostgreSQL funciona.

### PostgreSQL no WSL2

```bash
sudo service postgresql start
sudo -u postgres createuser --superuser "$USER"   # uma vez, para o seu usuário
```

### Configuração do projeto

```bash
bundle install
bin/rails db:create db:migrate
bin/dev            # servidor + build do Tailwind
```

`config/application.rb` deve conter:

```ruby
config.i18n.default_locale = :"pt-BR"
config.time_zone = "Brasilia"
```

A gem `rails-i18n` fornece os formatos de data, número e moeda em pt-BR usados nas telas (`l(data)`, `number_to_currency`).

## Testes

Os testes usam **Minitest**.

```bash
bin/rails test                                   # tudo
bin/rails test test/services                     # apenas services
bin/rails test test/services/mega_sena/stats     # apenas estatística
bin/rails test test/controllers/dashboard_controller_test.rb
```

| Pasta                          | O que cobre                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| `test/models`                  | `Draw`, `DrawFilter`                                                                                       |
| `test/services/mega_sena`      | Importador, validador histórico, cálculos estatísticos, combinatória, relatório e CSV                      |
| `test/controllers`             | Todas as telas: estado vazio, filtros, parâmetros inválidos, CSV                                           |
| `test/fixtures/files`          | Planilhas `.xlsx` **fictícias** para os testes de importação (pequena, estendida, divergente e com lacuna) |
| `test/support/draw_factory.rb` | `create_draw(numero, dezenas, date:)` para montar concursos nos testes                                     |

Os valores esperados das análises combinatórias são testados contra resultados calculados à mão. As fórmulas de dezenas consecutivas, faixas vazias e perfis de faixas também foram conferidas por simulação (Monte Carlo) durante o desenvolvimento.

## Uso pelo console

```ruby
# Importar uma planilha
batch = MegaSena::XlsxImporter.call(file_path: "tmp/megasena.xlsx", file_name: "megasena.xlsx")
batch.status            # => "succeeded" ou "failed"
batch.error_details     # detalhes se foi rejeitada

# Auditar a base inteira
MegaSena::HistoricalValidator.new.call["result"]   # => "passed", "warning" ou "failed"

# Frequência das dezenas
freq = MegaSena::Stats::Frequency.new(MegaSena::Stats::Dataset.load)
freq.most_frequent(5)

# Relatório de um período
scope  = DrawFilter.new(from: "2025-01-01", to: "2025-12-31").scope
report = MegaSena::Reports::PeriodReport.new(scope)
report.financial.total_revenue
```

## Convenções

- **Regras de negócio e cálculos em services** (`app/services/mega_sena`), nunca em controllers ou views.
- **Um objeto por análise** em `MegaSena::Stats`, recebendo um `Dataset` e devolvendo estruturas simples (`Struct` / `Data`).
- **Carregar o histórico uma vez** (`Dataset.load`) e calcular em memória.
- **Valores esperados por combinatória exata** em `Combinatorics`; nada de números "mágicos".
- **Filtros via `DrawFilter`**: todo parâmetro de período, dezena e paginação passa por ele, o que garante validação e links/exportações consistentes.
- **Locale pt-BR** para textos da interface; rótulos de status em `config/locales/pt-BR.yml`.
- **Gráficos em HTML/CSS/SVG** pelos helpers (`horizontal_bar`, `heat_cell`, `evolution_chart`); classes do Tailwind escritas por extenso para serem detectadas pelo build.
- **Testes** para todo service novo e para cada tela.
- Estado visível ao usuário em português; código e identificadores em inglês.

## Como adicionar uma nova análise

1. Crie a classe em `app/services/mega_sena/stats/` recebendo um `Dataset` (veja `ParityDistribution` como modelo simples).
2. Se houver valor esperado por acaso, adicione a fórmula em `Combinatorics` e um teste que confira a soma das probabilidades (= 1) e casos conhecidos.
3. Escreva o teste do service em `test/services/mega_sena/stats/`.
4. Use-a no controller da tela escolhida e exiba na view (reaproveite `horizontal_bar`, `percent`, `two_digits`).
5. Para incluí-la no relatório, adicione um método memorizado em `MegaSena::Reports::PeriodReport` e a seção em `reports/show`.
6. Se for exportável, acrescente um método em `MegaSena::Exports::CsvBuilder` e registre a seção em `ReportsController::CSV_SECTIONS`.
7. Documente a definição e a fórmula em [analises-estatisticas.md](analises-estatisticas.md).

## Como adicionar uma coluna da planilha

1. Crie a migration para a nova coluna em `draws`.
2. Inclua o cabeçalho em `COLUMN_ALIASES` e o tipo em `INTEGER_COLUMNS`, `DECIMAL_COLUMNS` ou `TEXT_COLUMNS` (`xlsx_importer.rb`).
3. Atualize as validações em `Draw` (e `Draw::MONEY_COLUMNS` / `COUNT_COLUMNS`, se for o caso).
4. Atualize `CsvBuilder::DRAW_HEADERS` e as telas que devam exibi-la.
5. Ajuste as planilhas de teste e os testes do importador.

Lembre-se de que a nova coluna passa a fazer parte da comparação de divergência: concursos já gravados terão `NULL` e a planilha terá um valor, o que será tratado como divergência. Planeje uma carga de correção explícita nesses casos.

## Desempenho

Com cerca de 3 mil concursos, todas as telas calculam em tempo aceitável sem cache. A análise de **ternos** é a mais cara (cerca de 60 mil combinações contadas por requisição). Se necessário, uma estratégia simples é cachear resultados usando `Draw.maximum(:contest_number)` como parte da chave, já que o histórico só muda quando uma importação é concluída.

## Segurança

- Não há autenticação: restrinja o acesso (rede local, VPN, proxy autenticado) antes de publicar.
- O upload aceita somente `.xlsx` de até 20 MB e valida o conteúdo antes de gravar.
- A gravação é transacional e protegida por restrições do banco.

---

## [← Voltar ao README](../README.md)

---
