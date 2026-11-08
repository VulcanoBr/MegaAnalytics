# MegaAnalytics

![Ruby](https://img.shields.io/badge/Ruby-3.2%2B-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1-D30001?logo=rubyonrails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-jsonb-4169E1?logo=postgresql&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-06B6D4?logo=tailwindcss&logoColor=white)
![Hotwire](https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-4B5563)

Aplicação web em Ruby on Rails que **armazena o histórico oficial da Mega-Sena** e oferece **análises estatísticas e matemáticas** sobre os resultados: frequência das dezenas, distribuições, combinações, repetições, relatórios por período e exportação de dados.

> A Mega-Sena é uma loteria administrada pela Caixa Econômica Federal, na qual são sorteadas seis dezenas entre 01 e 60.

## Sumário

- [Visão geral](#visão-geral)
- [Funcionalidades](#funcionalidades)
- [Telas e rotas](#telas-e-rotas)
- [Tecnologias](#tecnologias)
- [Início rápido](#início-rápido)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Documentação detalhada](#documentação-detalhada)
- [Aviso importante](#aviso-importante)
- [Roadmap](#roadmap)
- [Contribuindo](#contribuindo)
- [Licença](#licença)

## Visão geral

O MegaAnalytics foi concebido em torno de uma ideia simples: **primeiro garantir uma base de dados confiável, depois construir as análises sobre ela**.

1. **Dados confiáveis.** O histórico é importado da planilha oficial da Caixa (`.xlsx`). A importação é incremental, nunca duplica concursos e **nunca altera silenciosamente um concurso já gravado**: qualquer divergência rejeita o arquivo inteiro antes de gravar qualquer coisa. Cada importação gera um registro de auditoria e uma validação automática da integridade do histórico.
2. **Análises sobre o histórico.** Com os dados validados, o sistema calcula indicadores e os compara com o que se esperaria **por puro acaso** (valores exatos, calculados por combinatória), para que seja possível distinguir um padrão real de uma simples flutuação.
3. **Exploração e exportação.** Dashboard, consulta por concurso, relatórios por período, impressão e exportação em CSV.

## Funcionalidades

| Módulo                     | O que faz                                                                                                                                              | Documentação                                                     |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- |
| **Importação**             | Upload de planilha XLSX, importação incremental, detecção de arquivo repetido (SHA-256), rejeição em caso de divergência histórica, auditoria por lote | [docs/importacao.md](docs/importacao.md)                         |
| **Validação do histórico** | Verifica dezenas, faixas, datas, ordem cronológica, valores negativos, duplicados e lacunas na sequência                                               | [docs/importacao.md](docs/importacao.md#validação-do-histórico)  |
| **Dashboard**              | Indicadores gerais, mapa de calor das 60 dezenas, rankings, maior atraso, comparativo de períodos, pares/ímpares, soma e evolução histórica            | [docs/guia-de-uso.md](docs/guia-de-uso.md#dashboard)             |
| **Combinações**            | Pares e ternos mais frequentes; repetição de dezenas entre concursos consecutivos                                                                      | [docs/analises-estatisticas.md](docs/analises-estatisticas.md)   |
| **Distribuições**          | Dezenas consecutivas no mesmo concurso e distribuição por faixas numéricas                                                                             | [docs/analises-estatisticas.md](docs/analises-estatisticas.md)   |
| **Concursos**              | Lista filtrável e detalhe de cada concurso (dezenas, premiação, arrecadação)                                                                           | [docs/guia-de-uso.md](docs/guia-de-uso.md#concursos)             |
| **Relatórios**             | Relatório estatístico e financeiro por período, com impressão/PDF                                                                                      | [docs/guia-de-uso.md](docs/guia-de-uso.md#relatório-por-período) |
| **Exportação**             | CSV no padrão do Excel em português (concursos, frequência, pares, ternos)                                                                             | [docs/guia-de-uso.md](docs/guia-de-uso.md#exportação-csv)        |

## Telas e rotas

| Rota                  | Descrição                                              |
| --------------------- | ------------------------------------------------------ |
| `/` e `/dashboard`    | Dashboard estatístico                                  |
| `/draws`              | Consulta de concursos com filtros e paginação          |
| `/draws/:número`      | Detalhe de um concurso (ex.: `/draws/3080`)            |
| `/combinations`       | Pares, ternos e repetição entre concursos consecutivos |
| `/distributions`      | Dezenas consecutivas e faixas numéricas                |
| `/report`             | Relatório por período                                  |
| `/import_batches`     | Histórico de importações                               |
| `/import_batches/new` | Envio de uma nova planilha                             |
| `/up`                 | Health check                                           |

## Tecnologias

| Tecnologia                 | Finalidade                                           |
| -------------------------- | ---------------------------------------------------- |
| Ruby 3.2+                  | Linguagem                                            |
| Ruby on Rails 8.1          | Framework principal                                  |
| PostgreSQL                 | Banco relacional (usa `jsonb` e `CHECK constraints`) |
| Tailwind CSS               | Interface                                            |
| Hotwire (Turbo + Stimulus) | Interatividade e navegação                           |
| Roo                        | Leitura de planilhas XLSX                            |
| rails-i18n                 | Datas, números e moeda em pt-BR                      |
| Minitest                   | Testes automatizados                                 |

Os gráficos são HTML, CSS e SVG gerados no servidor; **não há dependência de bibliotecas de gráficos em JavaScript**.

## Início rápido

### Pré-requisitos

- Ruby 3.2 ou superior
- PostgreSQL em execução
- Bundler

### Instalação

```bash
git clone https://github.com/<seu-usuario>/MegaAnalytics.git
cd MegaAnalytics

bundle install
bin/rails db:create db:migrate
```

Confirme que `config/application.rb` contém:

```ruby
config.i18n.default_locale = :"pt-BR"
config.time_zone = "Brasilia"
```

### Executando

```bash
bin/dev
```

Acesse <http://localhost:3000>.

### Primeira carga de dados

1. Baixe a planilha oficial de resultados da Mega-Sena (`.xlsx`) no site de loterias da Caixa.
2. Abra **Importações → Nova importação** e envie o arquivo.
3. Veja o resultado do lote (inseridos, ignorados, erros e resultado da auditoria) na tela de detalhe da importação.

A partir daí o dashboard e as demais telas passam a exibir os dados. Para atualizar o histórico depois de novos sorteios, basta importar a planilha atualizada: apenas os concursos novos são inseridos.

### Testes

```bash
bin/rails test
```

Mais detalhes sobre o ambiente de desenvolvimento em [docs/desenvolvimento.md](docs/desenvolvimento.md).

## Estrutura do projeto

```text
app/
├── controllers/
│   ├── import_batches_controller.rb   # upload e histórico de importações
│   ├── dashboard_controller.rb        # dashboard estatístico
│   ├── combinations_controller.rb     # pares, ternos e repetições
│   ├── distributions_controller.rb    # consecutivas e faixas
│   ├── draws_controller.rb            # lista, detalhe e CSV de concursos
│   └── reports_controller.rb          # relatório por período e CSV
├── helpers/                           # gráficos em HTML/SVG e formatação
├── javascript/controllers/
│   └── print_controller.js            # botão Imprimir / PDF (Stimulus)
├── models/
│   ├── draw.rb                        # um concurso
│   ├── import_batch.rb                # auditoria de uma importação
│   └── draw_filter.rb                 # filtros de período, dezena e paginação
├── services/mega_sena/
│   ├── xlsx_importer.rb               # importação incremental
│   ├── historical_validator.rb        # auditoria da base
│   ├── stats/                         # cálculos estatísticos
│   ├── reports/period_report.rb       # relatório consolidado
│   └── exports/csv_builder.rb         # exportações CSV
└── views/
config/locales/pt-BR.yml
db/migrate/
test/                                  # testes + planilhas de exemplo em test/fixtures/files
docs/                                  # documentação detalhada
```

## Documentação detalhada

| Documento                                                      | Conteúdo                                                                   |
| -------------------------------------------------------------- | -------------------------------------------------------------------------- |
| [docs/arquitetura.md](docs/arquitetura.md)                     | Camadas, componentes, fluxos e princípios de projeto                       |
| [docs/banco-de-dados.md](docs/banco-de-dados.md)               | Tabelas, restrições, índices e consultas úteis                             |
| [docs/importacao.md](docs/importacao.md)                       | Fluxo de importação, regras, validação do histórico e solução de problemas |
| [docs/analises-estatisticas.md](docs/analises-estatisticas.md) | Definição e fórmula de cada análise, com valores esperados por acaso       |
| [docs/guia-de-uso.md](docs/guia-de-uso.md)                     | Tela a tela: parâmetros, filtros e exportações                             |
| [docs/desenvolvimento.md](docs/desenvolvimento.md)             | Ambiente, comandos, convenções e como estender o projeto                   |
| [docs/roadmap.md](docs/roadmap.md)                             | Fases concluídas e próximos passos                                         |

## Aviso importante

**Os sorteios da Mega-Sena são eventos independentes e aleatórios.** Todas as combinações de seis dezenas têm exatamente a mesma probabilidade, e resultados passados não alteram a chance dos futuros.

O MegaAnalytics é uma ferramenta **descritiva**: ele mostra o que aconteceu no histórico e o compara com o esperado por acaso. Nenhuma análise aqui permite prever resultados futuros ou aumentar a chance de ganhar. As telas repetem esse aviso nos pontos em que ele é mais relevante.

> **Segurança:** a aplicação **não possui autenticação** e permite enviar planilhas. Use-a em ambiente local ou protegido por uma camada de acesso (VPN, proxy com autenticação etc.); não a exponha publicamente como está.

## Roadmap

Todas as funcionalidades planejadas na especificação original estão implementadas. Sugestões de evolução estão em [docs/roadmap.md](docs/roadmap.md).

## Contribuindo

Contribuições são bem-vindas.

1. Faça um fork e crie uma branch: `git checkout -b minha-melhoria`.
2. Siga as convenções descritas em [docs/desenvolvimento.md](docs/desenvolvimento.md).
3. Inclua testes para o que alterar e garanta que `bin/rails test` passa.
4. Abra um Pull Request descrevendo a mudança.

## Licença

A definir. Adicione um arquivo `LICENSE` ao repositório e atualize esta seção.
