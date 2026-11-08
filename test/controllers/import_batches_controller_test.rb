require "test_helper"

class ImportBatchesControllerTest < ActionDispatch::IntegrationTest
  test "index responde com sucesso" do
    get import_batches_path
    assert_response :success
  end

  test "new responde com sucesso" do
    get new_import_batch_path
    assert_response :success
  end

  test "create sem arquivo volta para o formulário" do
    post import_batches_path
    assert_redirected_to new_import_batch_path
  end

  test "create com planilha válida importa os concursos" do
    file = fixture_file_upload("megasena_small.xlsx",
                               "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")

    assert_difference -> { Draw.count }, 3 do
      post import_batches_path, params: { file: file }
    end

    assert_redirected_to import_batch_path(ImportBatch.last)
  end
end
