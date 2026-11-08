module MegaSena
  module Stats
    # Compara a frequência (% dos concursos) de um período com todo o histórico.
    class PeriodComparison
      Row = Data.define(:number, :window_percent, :all_percent) do
        def delta = window_percent - all_percent
      end

      def initialize(window_entries, all_entries)
        all_by_number = all_entries.index_by(&:number)
        @rows = window_entries.map do |entry|
          Row.new(
            number: entry.number,
            window_percent: entry.percent_of_draws,
            all_percent: all_by_number.fetch(entry.number).percent_of_draws
          )
        end
      end

      attr_reader :rows

      def rising(limit = 5)
        rows.sort_by { |r| [ -r.delta, r.number ] }.first(limit)
      end

      def falling(limit = 5)
        rows.sort_by { |r| [ r.delta, r.number ] }.first(limit)
      end
    end
  end
end
