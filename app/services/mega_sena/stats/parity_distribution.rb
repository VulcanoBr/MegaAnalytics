module MegaSena
  module Stats
    # Quantos concursos tiveram 0..6 dezenas pares (e, por consequência, 6..0 ímpares).
    class ParityDistribution
      Bucket = Data.define(:evens, :odds, :count, :percent) do
        def label = "#{evens} pares / #{odds} ímpares"
      end

      def initialize(dataset)
        @dataset = dataset
      end

      def call
        total = @dataset.size
        counts = @dataset.each_with_object(Hash.new(0)) { |row, acc| acc[row.evens] += 1 }

        (0..6).map do |evens|
          count = counts[evens]
          Bucket.new(evens: evens, odds: 6 - evens, count: count, percent: total.zero? ? 0.0 : count * 100.0 / total)
        end
      end
    end
  end
end
