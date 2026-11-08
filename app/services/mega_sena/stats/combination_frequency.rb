module MegaSena
  module Stats
    # Frequência de pares (size: 2) ou ternos (size: 3) de dezenas.
    class CombinationFrequency
      Result = Data.define(:numbers, :count, :percent_of_draws, :lift, :last_seen_contest) do
        def label = numbers.map { |n| format("%02d", n) }.join(" – ")
      end

      attr_reader :size

      def initialize(dataset, size:)
        raise ArgumentError, "size deve ser 2 ou 3" unless [ 2, 3 ].include?(size)

        @dataset = dataset
        @size = size
      end

      # Quantas combinações distintas existem (C(60, size)).
      def total_possible(containing: nil)
        containing ? Combinatorics.binom(59, size - 1) : Combinatorics.binom(60, size)
      end

      def distinct_seen(containing: nil)
        return counts.size unless containing

        counts.keys.count { |combo| combo.include?(containing) }
      end

      def never_seen(containing: nil)
        total_possible(containing: containing) - distinct_seen(containing: containing)
      end

      # Percentual esperado dos concursos que contêm uma combinação específica.
      def expected_percent
        Combinatorics.probability_of_set(size) * 100
      end

      def top(limit = 20, containing: nil)
        selected = counts.select { |combo, _| containing.nil? || combo.include?(containing) }
        selected.sort_by { |combo, count| [ -count, combo ] }.first(limit).map { |combo, count| build(combo, count) }
      end

      private

      def counts
        tally.first
      end

      def last_seen
        tally.last
      end

      def tally
        @tally ||= begin
          counts = Hash.new(0)
          last_seen = {}

          @dataset.each do |row|
            row.numbers.sort.combination(size) do |combo|
              counts[combo] += 1
              last_seen[combo] = row.contest_number
            end
          end

          [ counts, last_seen ]
        end
      end

      def build(combo, count)
        expected_count = @dataset.size * Combinatorics.probability_of_set(size)
        Result.new(
          numbers: combo,
          count: count,
          percent_of_draws: count * 100.0 / @dataset.size,
          lift: expected_count.zero? ? 0.0 : count / expected_count,
          last_seen_contest: last_seen[combo]
        )
      end
    end
  end
end
