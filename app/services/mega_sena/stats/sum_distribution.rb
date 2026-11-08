module MegaSena
  module Stats
    # Distribuição da soma das seis dezenas, agrupada em faixas.
    class SumDistribution
      Bucket = Data.define(:from, :to, :count, :percent) do
        def label = "#{from}–#{to}"
      end

      def initialize(dataset, bucket_size: 20)
        @dataset = dataset
        @bucket_size = bucket_size
      end

      def sums
        @sums ||= @dataset.map(&:sum)
      end

      def min = sums.min
      def max = sums.max
      def mean = sums.empty? ? nil : sums.sum.to_f / sums.size

      def median
        return nil if sums.empty?

        sorted = sums.sort
        middle = sorted.size / 2
        sorted.size.odd? ? sorted[middle].to_f : (sorted[middle - 1] + sorted[middle]) / 2.0
      end

      def buckets
        return [] if sums.empty?

        counts = sums.each_with_object(Hash.new(0)) { |sum, acc| acc[sum / @bucket_size] += 1 }
        (counts.keys.min..counts.keys.max).map do |index|
          from = index * @bucket_size
          Bucket.new(
            from: from,
            to: from + @bucket_size - 1,
            count: counts[index],
            percent: counts[index] * 100.0 / sums.size
          )
        end
      end
    end
  end
end
