module MegaSena
  module Stats
    # Frequência de cada dezena (01–60) em um conjunto de concursos.
    #
    # draws_after_last: quantos concursos DO CONJUNTO vieram depois da última aparição da dezena
    #   (0 = saiu no último concurso do conjunto; nil = nunca saiu no conjunto).
    # draws_since_last: diferença em números de concurso até o último concurso do conjunto
    #   (igual a draws_after_last quando o conjunto é contíguo).
    class Frequency
      Entry = Struct.new(
        :number, :count, :percent_of_draws, :percent_of_numbers,
        :last_seen_contest, :draws_since_last, :draws_after_last, :average_gap,
        keyword_init: true
      )

      # Em cada concurso saem 6 de 60 dezenas: 10% dos concursos contêm uma dada dezena.
      EXPECTED_PERCENT_OF_DRAWS = 10.0

      def initialize(dataset)
        @dataset = dataset
      end

      def entries
        @entries ||= build_entries
      end

      def most_frequent(limit = 10)
        entries.sort_by { |e| [ -e.count, e.number ] }.first(limit)
      end

      def least_frequent(limit = 10)
        entries.sort_by { |e| [ e.count, e.number ] }.first(limit)
      end

      # Dezenas há mais concursos sem aparecer (dentro do conjunto analisado)
      def most_overdue(limit = 10)
        entries.select(&:draws_since_last).sort_by { |e| [ -e.draws_since_last, e.number ] }.first(limit)
      end

      def max_count = entries.map(&:count).max
      def min_count = entries.map(&:count).min

      private

      def build_entries
        total = @dataset.size
        return [] if total.zero?

        counts = Hash.new(0)
        first_seen = {}
        last_seen = {}
        last_index = {}

        @dataset.each_with_index do |row, index|
          row.numbers.each do |number|
            counts[number] += 1
            first_seen[number] ||= row.contest_number
            last_seen[number] = row.contest_number
            last_index[number] = index
          end
        end

        last_contest = @dataset.last_row.contest_number

        (1..60).map do |number|
          count = counts[number]
          Entry.new(
            number: number,
            count: count,
            percent_of_draws: count * 100.0 / total,
            percent_of_numbers: count * 100.0 / (total * 6),
            last_seen_contest: last_seen[number],
            draws_since_last: last_seen[number] ? last_contest - last_seen[number] : nil,
            draws_after_last: last_index[number] ? total - 1 - last_index[number] : nil,
            average_gap: count > 1 ? (last_seen[number] - first_seen[number]).to_f / (count - 1) : nil
          )
        end
      end
    end
  end
end
