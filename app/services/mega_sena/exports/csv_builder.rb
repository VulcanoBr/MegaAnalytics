require "csv"

module MegaSena
  module Exports
    # Gera CSV pronto para o Excel em português: separador ";", vírgula decimal,
    # datas dd/mm/aaaa e BOM UTF-8 (para os acentos abrirem corretamente).
    class CsvBuilder
      BOM = "\uFEFF".freeze
      SEPARATOR = ";".freeze
      COMBINATION_LIMIT = 100

      DRAW_HEADERS = [
        "Concurso", "Data", "Dezena 1", "Dezena 2", "Dezena 3", "Dezena 4", "Dezena 5", "Dezena 6",
        "Ganhadores Sena", "Prêmio Sena", "Ganhadores Quina", "Prêmio Quina", "Ganhadores Quadra", "Prêmio Quadra",
        "Cidade / UF", "Acumulado Sena", "Arrecadação Total", "Estimativa Prêmio",
        "Acumulado Sorteio Especial", "Observação"
      ].freeze

      class << self
        def draws(scope)
          rows = scope.map do |draw|
            [
              draw.contest_number, date(draw.draw_date), *draw.numbers,
              draw.winners_sena, decimal(draw.prize_sena), draw.winners_quina, decimal(draw.prize_quina),
              draw.winners_quadra, decimal(draw.prize_quadra), draw.city_uf, decimal(draw.accumulated_sena),
              decimal(draw.total_revenue), decimal(draw.estimated_prize), decimal(draw.special_draw_accumulated),
              draw.observation
            ]
          end

          generate(DRAW_HEADERS, rows)
        end

        # source: PeriodReport (responde a #frequency) ou Stats::Frequency
        def frequency(source)
          entries = source.respond_to?(:frequency) ? source.frequency.entries : source.entries
          headers = [ "Dezena", "Vezes", "% dos concursos", "% das dezenas", "Último concurso",
                      "Concursos desde a última aparição", "Intervalo médio (concursos)",
                      "Concursos após a última aparição (entre os encontrados)" ]
          rows = entries.map do |entry|
            [
              format("%02d", entry.number), entry.count, decimal(entry.percent_of_draws), decimal(entry.percent_of_numbers),
              entry.last_seen_contest, entry.draws_since_last, decimal(entry.average_gap), entry.draws_after_last
            ]
          end

          generate(headers, rows)
        end

        def pairs(report, limit: COMBINATION_LIMIT)
          combinations(report.pairs, limit)
        end

        def triples(report, limit: COMBINATION_LIMIT)
          combinations(report.triples, limit)
        end

        private

        def combinations(frequency, limit)
          size = frequency.size
          headers = [ "Combinação" ] + (1..size).map { |i| "Dezena #{i}" } +
                    [ "Vezes", "% dos concursos", "Vezes acima do esperado", "Último concurso" ]
          rows = frequency.top(limit).map do |result|
            [ result.label ] + result.numbers.map { |n| format("%02d", n) } +
              [ result.count, decimal(result.percent_of_draws, 3), decimal(result.lift, 2), result.last_seen_contest ]
          end

          generate(headers, rows)
        end

        def generate(headers, rows)
          BOM + CSV.generate(col_sep: SEPARATOR) do |csv|
            csv << headers
            rows.each { |row| csv << row }
          end
        end

        def decimal(value, digits = 2)
          return nil if value.nil?

          format("%.#{digits}f", value).tr(".", ",")
        end

        def date(value)
          value&.strftime("%d/%m/%Y")
        end
      end
    end
  end
end
