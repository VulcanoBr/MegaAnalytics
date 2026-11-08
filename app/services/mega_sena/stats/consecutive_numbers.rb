module MegaSena
  module Stats
    # Dezenas consecutivas no MESMO concurso (ex.: 12 e 13; 40, 41 e 42).
    # "Par consecutivo" = duas dezenas n e n+1 sorteadas juntas.
    class ConsecutiveNumbers
      Bucket = Data.define(:pairs, :count, :percent, :expected_percent)
      Occurrence = Data.define(:contest_number, :sequences)
      AdjacentPair = Data.define(:low, :high, :count, :percent_of_draws, :last_seen_contest) do
        def label = format("%02d – %02d", low, high)
      end

      # Em média, 59 pares possíveis × 1/118 cada = 0,5 par consecutivo por concurso.
      EXPECTED_MEAN_PAIRS = 0.5

      def initialize(dataset)
        @dataset = dataset
      end

      # Sequências (runs) de 2 ou mais dezenas seguidas em um conjunto de dezenas.
      def self.runs(numbers)
        numbers.sort.slice_when { |a, b| b != a + 1 }.select { |run| run.size >= 2 }
      end

      def distribution
        total = analyzed.size
        counts = analyzed.each_with_object(Hash.new(0)) { |(_, runs), acc| acc[pairs_in(runs)] += 1 }

        (0..5).map do |pairs|
          Bucket.new(
            pairs: pairs,
            count: counts[pairs],
            percent: total.zero? ? 0.0 : counts[pairs] * 100.0 / total,
            expected_percent: Combinatorics.probability_of_adjacent_pairs(pairs) * 100
          )
        end
      end

      def mean_pairs
        return nil if analyzed.empty?

        analyzed.sum { |(_, runs)| pairs_in(runs) }.to_f / analyzed.size
      end

      def draws_with_sequence
        analyzed.count { |(_, runs)| runs.any? }
      end

      def percent_with_sequence
        analyzed.empty? ? 0.0 : draws_with_sequence * 100.0 / analyzed.size
      end

      def expected_percent_with_sequence
        100.0 - Combinatorics.probability_of_adjacent_pairs(0) * 100
      end

      # Maior sequência já sorteada (ex.: 4 dezenas seguidas).
      def longest
        best = analyzed.max_by { |_, runs| runs.map(&:size).max.to_i }
        return nil if best.nil? || best.last.empty?

        Occurrence.new(contest_number: best.first.contest_number, sequences: [ best.last.max_by(&:size) ])
      end

      # Pares n–(n+1) que mais saíram juntos.
      def top_adjacent_pairs(limit = 10)
        counts = Hash.new(0)
        last_seen = {}

        analyzed.each do |row, runs|
          runs.each do |run|
            run.each_cons(2) do |low, high|
              counts[[ low, high ]] += 1
              last_seen[[ low, high ]] = row.contest_number
            end
          end
        end

        counts.sort_by { |pair, count| [ -count, pair ] }.first(limit).map do |(low, high), count|
          AdjacentPair.new(
            low: low, high: high, count: count,
            percent_of_draws: count * 100.0 / analyzed.size,
            last_seen_contest: last_seen[[ low, high ]]
          )
        end
      end

      # Últimos concursos que tiveram sequências, do mais recente ao mais antigo.
      def recent(limit = 10)
        analyzed.reverse.select { |(_, runs)| runs.any? }.first(limit).map do |row, runs|
          Occurrence.new(contest_number: row.contest_number, sequences: runs)
        end
      end

      private

      def analyzed
        @analyzed ||= @dataset.map { |row| [ row, self.class.runs(row.numbers) ] }
      end

      def pairs_in(runs)
        runs.sum { |run| run.size - 1 }
      end
    end
  end
end
