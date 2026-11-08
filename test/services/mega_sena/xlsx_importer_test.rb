require "test_helper"

class MegaSena::XlsxImporterTest < ActiveSupport::TestCase
  def import(fixture)
    MegaSena::XlsxImporter.call(file_path: file_fixture(fixture).to_s, file_name: fixture)
  end

  test "importa uma planilha nova" do
    batch = import("megasena_small.xlsx")

    assert batch.succeeded?
    assert_equal 3, batch.total_rows
    assert_equal 3, batch.inserted_rows
    assert_equal 0, batch.skipped_rows
    assert_equal 3, Draw.count
    assert_equal "passed", batch.validation_result
    assert_equal 64, batch.file_sha256.length
  end

  test "converte valores monetários, datas e textos" do
    import("megasena_small.xlsx")
    draw = Draw.find_by!(contest_number: 2)

    assert_equal Date.new(2020, 1, 8), draw.draw_date
    assert_equal BigDecimal("2500000.75"), draw.prize_sena
    assert_equal "SAO PAULO / SP", draw.city_uf
    assert_equal [ 7, 15, 22, 30, 44, 59 ], draw.numbers
  end

  test "rejeita o mesmo arquivo importado duas vezes" do
    import("megasena_small.xlsx")
    batch = import("megasena_small.xlsx")

    assert batch.failed?
    assert_equal 3, Draw.count
    assert_match(/já foi importado/, batch.error_details.first["message"])
  end

  test "importação incremental insere só os concursos novos" do
    import("megasena_small.xlsx")
    batch = import("megasena_extended.xlsx")

    assert batch.succeeded?
    assert_equal 5, batch.total_rows
    assert_equal 2, batch.inserted_rows
    assert_equal 3, batch.skipped_rows
    assert_equal 0, batch.updated_rows
    assert_equal 5, Draw.count
  end

  test "divergência em concurso histórico rejeita tudo e não grava nada" do
    import("megasena_small.xlsx")
    original_prize = Draw.find_by!(contest_number: 2).prize_sena

    batch = import("megasena_divergent.xlsx")

    assert batch.failed?
    assert_equal 3, Draw.count
    assert_nil Draw.find_by(contest_number: 4)
    assert_equal original_prize, Draw.find_by!(contest_number: 2).prize_sena
    assert_equal 2, batch.error_details.last["contest_number"]
  end

  test "rejeita planilha com lacuna na sequência" do
    batch = import("megasena_gap.xlsx")

    assert batch.failed?
    assert_equal 0, Draw.count
  end

  test "rejeita arquivo com extensão diferente de xlsx" do
    batch = MegaSena::XlsxImporter.call(file_path: file_fixture("megasena_small.xlsx").to_s, file_name: "dados.csv")

    assert batch.failed?
    assert_equal 0, Draw.count
  end
end
