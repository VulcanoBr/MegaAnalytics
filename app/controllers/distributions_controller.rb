class DistributionsController < ApplicationController
  def show
    @all = MegaSena::Stats::Dataset.load
    return if @all.empty?

    @window_key = DashboardController::WINDOWS.key?(params[:window]) ? params[:window] : "all"
    @dataset = @all.window(DashboardController::WINDOWS[@window_key])

    @consecutive = MegaSena::Stats::ConsecutiveNumbers.new(@dataset)
    @ranges = MegaSena::Stats::RangeDistribution.new(@dataset)
  end
end
