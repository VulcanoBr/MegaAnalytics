module MegaSena
  module Reports
    # Reúne, para um conjunto de concursos (normalmente um período), todas as análises
    # estatísticas e o resumo financeiro. Tudo é calculado sob demanda e memorizado.
    class PeriodReport
      TOP = 10

      Financial = Data.define(
        :total_revenue, :average_revenue, :draws_with_sena_winner, :draws_without_sena_winner,
        :total_sena_prizes, :largest_sena_prize_draw, :largest_accumulated_draw
      )

      attr_reader :scope

      def initialize(scope)
        @scope = scope
      end

      def dataset
        @dataset ||= Stats::Dataset.load(scope)
      end

      def empty? = dataset.empty?
      def draws_count = dataset.size
      def first_row = dataset.first_row
      def last_row = dataset.last_row

      def frequency = @frequency ||= Stats::Frequency.new(dataset)
      def parity = @parity ||= Stats::ParityDistribution.new(dataset).call
      def sums = @sums ||= Stats::SumDistribution.new(dataset)
      def ranges = @ranges ||= Stats::RangeDistribution.new(dataset)
      def consecutive = @consecutive ||= Stats::ConsecutiveNumbers.new(dataset)
      def repetition = @repetition ||= Stats::ConsecutiveRepetition.new(dataset)
      def pairs = @pairs ||= Stats::CombinationFrequency.new(dataset, size: 2)
      def triples = @triples ||= Stats::CombinationFrequency.new(dataset, size: 3)

      def financial
        @financial ||= begin
          base = scope.reorder(nil)
          total = base.sum(:total_revenue)
          count = base.count

          Financial.new(
            total_revenue: total,
            average_revenue: count.zero? ? 0 : total / count,
            draws_with_sena_winner: base.where("winners_sena > 0").count,
            draws_without_sena_winner: base.where("winners_sena = 0").count,
            total_sena_prizes: base.sum("winners_sena * prize_sena"),
            largest_sena_prize_draw: base.where("prize_sena > 0").reorder(prize_sena: :desc).first,
            largest_accumulated_draw: base.where("accumulated_sena > 0").reorder(accumulated_sena: :desc).first
          )
        end
      end
    end
  end
end
