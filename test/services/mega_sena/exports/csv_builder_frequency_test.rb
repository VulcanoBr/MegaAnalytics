require "test_helper"
require "csv"
require "support/draw_factory"

class MegaSena::Exports::CsvBuilderFrequencyTest < ActiveSupport::TestCase
  include DrawFactory

  test "frequência exporta a coluna de concursos após a última aparição" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    create_draw(2, [ 7, 8, 9, 10, 11, 12 ])
    frequency = MegaSena::Stats::Frequency.new(MegaSena::Stats::Dataset.load)

    csv = MegaSena::Exports::CsvBuilder.frequency(frequency)   # aceita Frequency diretamente
    rows = CSV.parse(csv.delete_prefix("\uFEFF"), col_sep: ";", headers: true)
    column = "Concursos após a última aparição (entre os encontrados)"

    assert_equal 60, rows.size
    assert_equal "1", rows.find { |r| r["Dezena"] == "01" }[column]
    assert_equal "0", rows.find { |r| r["Dezena"] == "07" }[column]
    assert_nil rows.find { |r| r["Dezena"] == "60" }[column]
  end

  test "continua aceitando um PeriodReport" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    report = MegaSena::Reports::PeriodReport.new(Draw.all)

    assert_includes MegaSena::Exports::CsvBuilder.frequency(report), "Dezena;Vezes"
  end
end
