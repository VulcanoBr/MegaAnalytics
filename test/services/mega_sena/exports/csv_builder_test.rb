require "test_helper"
require "csv"
require "support/draw_factory"

class MegaSena::Exports::CsvBuilderTest < ActiveSupport::TestCase
  include DrawFactory

  def parse(csv)
    assert csv.start_with?("\uFEFF"), "esperava BOM UTF-8"
    CSV.parse(csv.delete_prefix("\uFEFF"), col_sep: ";", headers: true)
  end

  setup do
    draw = create_draw(1, [ 1, 2, 3, 4, 5, 6 ], date: Date.new(2020, 1, 2))
    draw.update!(winners_sena: 1, prize_sena: 1234.5, total_revenue: 10, city_uf: "SAO PAULO / SP", observation: "teste")
    @report = MegaSena::Reports::PeriodReport.new(Draw.all)
  end

  test "exporta concursos com datas e decimais no padrão brasileiro" do
    rows = parse(MegaSena::Exports::CsvBuilder.draws(DrawFilter.new.scope))

    assert_equal 20, rows.headers.size
    assert_equal 1, rows.size
    row = rows.first
    assert_equal "1", row["Concurso"]
    assert_equal "02/01/2020", row["Data"]
    assert_equal "6", row["Dezena 6"]
    assert_equal "1234,50", row["Prêmio Sena"]
    assert_equal "10,00", row["Arrecadação Total"]
    assert_equal "SAO PAULO / SP", row["Cidade / UF"]
  end

  test "exporta frequência das 60 dezenas" do
    rows = parse(MegaSena::Exports::CsvBuilder.frequency(@report))

    assert_equal 60, rows.size
    one = rows.find { |r| r["Dezena"] == "01" }
    assert_equal "1", one["Vezes"]
    assert_equal "100,00", one["% dos concursos"]
    sixty = rows.find { |r| r["Dezena"] == "60" }
    assert_equal "0", sixty["Vezes"]
    assert_nil sixty["Último concurso"]
  end

  test "exporta pares e ternos" do
    pairs = parse(MegaSena::Exports::CsvBuilder.pairs(@report))
    assert_equal 15, pairs.size
    assert_equal "01 – 02", pairs.first["Combinação"]
    assert_equal "1", pairs.first["Vezes"]

    triples = parse(MegaSena::Exports::CsvBuilder.triples(@report))
    assert_equal 20, triples.size
    assert_includes triples.headers, "Dezena 3"
  end

  test "respeita o limite de combinações" do
    pairs = parse(MegaSena::Exports::CsvBuilder.pairs(@report, limit: 5))
    assert_equal 5, pairs.size
  end
end
