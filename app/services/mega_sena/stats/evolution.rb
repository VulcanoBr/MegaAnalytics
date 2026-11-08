module MegaSena
  module Stats
    # Evolução histórica da frequência de uma dezena, em blocos de N concursos.
    class Evolution
      Point = Data.define(:from, :to, :draws, :count, :percent) do
        def label = "#{from}–#{to}"
      end

      def initialize(dataset, number:, block_size: 100)
        @dataset = dataset
        @number = number
        @block_size = block_size
      end

      def call
        @dataset.group_by { |row| (row.contest_number - 1) / @block_size }.sort.map do |_, rows|
          count = rows.count { |row| row.numbers.include?(@number) }
          Point.new(
            from: rows.first.contest_number,
            to: rows.last.contest_number,
            draws: rows.size,
            count: count,
            percent: count * 100.0 / rows.size
          )
        end
      end
    end
  end
end
