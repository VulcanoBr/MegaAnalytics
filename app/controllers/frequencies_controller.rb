class FrequenciesController < ApplicationController
  SORTS = %w[number count delay].freeze

  def show
    @filter = DrawFilter.new(params)
    flash.now[:alert] = @filter.error_message unless @filter.valid?

    @dataset = MegaSena::Stats::Dataset.load(@filter.scope)
    @frequency = MegaSena::Stats::Frequency.new(@dataset)
    @sort = SORTS.include?(params[:sort]) ? params[:sort] : "number"
    @entries = sort_entries(@frequency.entries)
    @last_contest = Draw.maximum(:contest_number)

    respond_to do |format|
      format.html
      format.csv do
        name = [ "megasena_frequencia", @filter.filename_suffix.presence ].compact.join("_")
        send_data MegaSena::Exports::CsvBuilder.frequency(@frequency),
                  filename: "#{name}.csv", type: "text/csv; charset=utf-8"
      end
    end
  end

  private

  def sort_entries(entries)
    case @sort
    when "count" then entries.sort_by { |e| [ -e.count, e.number ] }
    when "delay" then entries.sort_by { |e| [ -(e.draws_after_last || Float::INFINITY), e.number ] }
    else entries
    end
  end
end
