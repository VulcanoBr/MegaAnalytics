class DashboardController < ApplicationController
  # chave da URL => quantidade de concursos (nil = todo o histórico)
  WINDOWS = { "50" => 50, "100" => 100, "500" => 500, "all" => nil }.freeze
  BLOCK_SIZES = [ 50, 100, 200, 500 ].freeze

  def show
    @all = MegaSena::Stats::Dataset.load
    return if @all.empty?

    @window_key = WINDOWS.key?(params[:window]) ? params[:window] : "all"
    @dataset = @all.window(WINDOWS[@window_key])

    @frequency = MegaSena::Stats::Frequency.new(@dataset)
    @entries = @frequency.entries
    @most_frequent = @frequency.most_frequent(10)
    @least_frequent = @frequency.least_frequent(10)
    @most_overdue = @frequency.most_overdue(10)

    @parity = MegaSena::Stats::ParityDistribution.new(@dataset).call
    @sums = MegaSena::Stats::SumDistribution.new(@dataset)

    if WINDOWS[@window_key]
      all_entries = MegaSena::Stats::Frequency.new(@all).entries
      @comparison = MegaSena::Stats::PeriodComparison.new(@entries, all_entries)
    end

    @selected_number = selected_number
    @block_size = BLOCK_SIZES.include?(params[:block].to_i) ? params[:block].to_i : 100
    @evolution = MegaSena::Stats::Evolution.new(@all, number: @selected_number, block_size: @block_size).call
  end

  private

  def selected_number
    number = Integer(params[:number], exception: false)
    number&.between?(1, 60) ? number : @most_frequent.first.number
  end
end
