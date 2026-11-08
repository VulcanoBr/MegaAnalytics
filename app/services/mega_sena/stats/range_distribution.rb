module MegaSena
  module Stats
    # Distribuição das dezenas por faixas numéricas (padrão: 01–10, 11–20, ..., 51–60).
    class RangeDistribution
      Band = Data.define(:from, :to, :occurrences, :percent_of_numbers, :mean_per_draw, :empty_draws, :empty_percent) do
        def label = format("%02d–%02d", from, to)
      end

      # pattern: dezenas por faixa em ordem decrescente, faixas vazias omitidas (ex.: [2, 1, 1, 1, 1])
      Profile = Data.define(:pattern, :count, :percent, :expected_percent) do
        def label = pattern.join("-")
      end

      attr_reader :band_size

      def initialize(dataset, band_size: 10)
        raise ArgumentError, "band_size deve dividir 60" unless (60 % band_size).zero?

        @dataset = dataset
        @band_size = band_size
      end

      def band_count = 60 / band_size
      def expected_percent_of_numbers = 100.0 / band_count
      def expected_mean_per_draw = 6.0 / band_count
      def expected_empty_percent = Combinatorics.probability_of_empty_band(band_size) * 100

      def bands
        @bands ||= begin
          total = vectors.size

          (0...band_count).map do |index|
            occurrences = vectors.sum { |vector| vector[index] }
            empty = vectors.count { |vector| vector[index].zero? }

            Band.new(
              from: index * band_size + 1,
              to: (index + 1) * band_size,
              occurrences: occurrences,
              percent_of_numbers: total.zero? ? 0.0 : occurrences * 100.0 / (total * 6),
              mean_per_draw: total.zero? ? 0.0 : occurrences.to_f / total,
              empty_draws: empty,
              empty_percent: total.zero? ? 0.0 : empty * 100.0 / total
            )
          end
        end
      end

      def profiles
        @profiles ||= begin
          total = vectors.size
          observed = vectors.map { |vector| vector.sort.reverse.reject(&:zero?) }.tally
          expected = Combinatorics.band_profile_probabilities(band_size: band_size)

          (expected.keys | observed.keys).map do |pattern|
            Profile.new(
              pattern: pattern,
              count: observed[pattern] || 0,
              percent: total.zero? ? 0.0 : (observed[pattern] || 0) * 100.0 / total,
              expected_percent: (expected[pattern] || 0.0) * 100
            )
          end.sort_by { |profile| [ -profile.expected_percent, profile.pattern ] }
        end
      end

      private

      # Para cada concurso: quantas dezenas caíram em cada faixa.
      def vectors
        @vectors ||= @dataset.map do |row|
          Array.new(band_count, 0).tap do |counts|
            row.numbers.each { |number| counts[(number - 1) / band_size] += 1 }
          end
        end
      end
    end
  end
end
