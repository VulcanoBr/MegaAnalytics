require "set"

module MegaSena
  module Stats
    # Quantas dezenas de um concurso já tinham saído no concurso imediatamente anterior.
    class ConsecutiveRepetition
      Bucket = Data.define(:repeated, :count, :percent, :expected_percent)
      NumberRate = Data.define(:number, :repeats, :opportunities) do
        def rate = opportunities.zero? ? 0.0 : repeats * 100.0 / opportunities
      end
      Occurrence = Data.define(:contest_number, :previous_contest, :repeated)

      def initialize(dataset)
        @dataset = dataset
      end

      def pairs_count = occurrences.size

      def empty? = occurrences.empty?

      def distribution
        total = occurrences.size
        counts = occurrences.each_with_object(Hash.new(0)) { |o, acc| acc[o.repeated.size] += 1 }

        (0..6).map do |k|
          Bucket.new(
            repeated: k,
            count: counts[k],
            percent: total.zero? ? 0.0 : counts[k] * 100.0 / total,
            expected_percent: Combinatorics.probability_of_repeats(k) * 100
          )
        end
      end

      def mean_repeated
        return nil if empty?

        occurrences.sum { |o| o.repeated.size }.to_f / occurrences.size
      end

      # Esperado por acaso: 6 × 6 / 60 = 0,6 dezena repetida por concurso.
      def expected_mean = 36.0 / 60

      # Dezenas que mais se repetiram no concurso seguinte ao que saíram.
      def number_rates(limit = 10)
        stats.values.sort_by { |r| [ -r.repeats, r.number ] }.first(limit)
      end

      # Últimos concursos com pelo menos uma dezena repetida, do mais recente ao mais antigo.
      def recent(limit = 10)
        occurrences.reverse.select { |o| o.repeated.any? }.first(limit)
      end

      private

      def occurrences
        @occurrences ||= @dataset.each_cons(2).filter_map do |previous, current|
          next unless current.contest_number == previous.contest_number + 1

          Occurrence.new(
            contest_number: current.contest_number,
            previous_contest: previous.contest_number,
            repeated: (previous.numbers & current.numbers).sort
          )
        end
      end

      def stats
        @stats ||= begin
          rates = Hash.new(0)
          opportunities = Hash.new(0)

          @dataset.each_cons(2) do |previous, current|
            next unless current.contest_number == previous.contest_number + 1

            current_numbers = current.numbers.to_set
            previous.numbers.each do |number|
              opportunities[number] += 1
              rates[number] += 1 if current_numbers.include?(number)
            end
          end

          opportunities.keys.to_h do |number|
            [ number, NumberRate.new(number: number, repeats: rates[number], opportunities: opportunities[number]) ]
          end
        end
      end
    end
  end
end
