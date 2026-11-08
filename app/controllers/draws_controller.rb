class DrawsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    redirect_to draws_path, alert: "Concurso não encontrado."
  end

  def index
    if params[:contest].present?
      draw = Draw.find_by(contest_number: Integer(params[:contest], exception: false))
      return redirect_to(draw_path(draw)) if draw

      flash.now[:alert] = "Concurso #{params[:contest]} não encontrado."
    end

    @filter = DrawFilter.new(params)
    flash.now[:alert] = @filter.error_message unless @filter.valid?
    scope = @filter.scope

    respond_to do |format|
      format.html do
        @total = scope.count
        @total_pages = [ (@total / @filter.per_page.to_f).ceil, 1 ].max
        @page = [ @filter.page, @total_pages ].min
        @draws = scope.offset((@page - 1) * @filter.per_page).limit(@filter.per_page)
      end

      format.csv do
        name = [ "megasena_concursos", @filter.filename_suffix.presence ].compact.join("_")
        send_data MegaSena::Exports::CsvBuilder.draws(scope),
                  filename: "#{name}.csv", type: "text/csv; charset=utf-8"
      end
    end
  end

  def show
    @draw = Draw.find_by!(contest_number: params[:id])
    @previous = Draw.find_by(contest_number: @draw.contest_number - 1)
    @next = Draw.find_by(contest_number: @draw.contest_number + 1)
    @runs = MegaSena::Stats::ConsecutiveNumbers.runs(@draw.numbers)
    @repeated = @previous ? (@previous.numbers & @draw.numbers).sort : nil
    @band_counts = @draw.band_counts
  end
end
