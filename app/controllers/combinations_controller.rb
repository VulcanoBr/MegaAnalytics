class CombinationsController < ApplicationController
  LIMITS = [ 10, 20, 50 ].freeze

  def show
    @all = MegaSena::Stats::Dataset.load
    return if @all.empty?

    @window_key = DashboardController::WINDOWS.key?(params[:window]) ? params[:window] : "all"
    @dataset = @all.window(DashboardController::WINDOWS[@window_key])

    number = Integer(params[:number], exception: false)
    @filter_number = number if number&.between?(1, 60)
    @limit = LIMITS.include?(params[:limit].to_i) ? params[:limit].to_i : 20

    @pairs = MegaSena::Stats::CombinationFrequency.new(@dataset, size: 2)
    @triples = MegaSena::Stats::CombinationFrequency.new(@dataset, size: 3)
    @top_pairs = @pairs.top(@limit, containing: @filter_number)
    @top_triples = @triples.top(@limit, containing: @filter_number)

    @repetition = MegaSena::Stats::ConsecutiveRepetition.new(@dataset)
  end
end
