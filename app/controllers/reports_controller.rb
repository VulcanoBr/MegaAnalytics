class ReportsController < ApplicationController
  CSV_SECTIONS = {
    "frequency" => :frequency,
    "pairs" => :pairs,
    "triples" => :triples
  }.freeze

  def show
    @filter = DrawFilter.new(params)
    flash.now[:alert] = @filter.error_message unless @filter.valid?
    @report = MegaSena::Reports::PeriodReport.new(@filter.scope)

    respond_to do |format|
      format.html
      format.csv { export_csv }
    end
  end

  private

  def export_csv
    method = CSV_SECTIONS[params[:section]]
    return redirect_to(report_path(@filter.to_params), alert: "Seção de exportação inválida.") unless method

    name = [ "megasena_#{params[:section]}", @filter.filename_suffix.presence ].compact.join("_")
    send_data MegaSena::Exports::CsvBuilder.public_send(method, @report),
              filename: "#{name}.csv", type: "text/csv; charset=utf-8"
  end
end
