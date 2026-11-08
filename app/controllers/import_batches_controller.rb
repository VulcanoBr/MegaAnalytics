class ImportBatchesController < ApplicationController
  def index
    @batches = ImportBatch.order(created_at: :desc).limit(50)
    @total_draws = Draw.count
    @first_draw = Draw.order(:contest_number).first
    @last_draw = Draw.order(:contest_number).last
  end

  def new
  end

  def show
    @batch = ImportBatch.find(params[:id])
  end

  def create
    upload = params[:file]

    if upload.blank?
      redirect_to new_import_batch_path, alert: "Selecione um arquivo .xlsx."
      return
    end

    batch = MegaSena::XlsxImporter.call(
      file_path: upload.tempfile.path,
      file_name: upload.original_filename
    )

    if batch.succeeded?
      redirect_to batch, notice: "Importação concluída: #{batch.inserted_rows} concurso(s) novo(s)."
    else
      redirect_to batch, alert: "Importação rejeitada. Veja os detalhes abaixo."
    end
  end
end
