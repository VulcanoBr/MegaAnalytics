require "test_helper"
require "support/draw_factory"

class DrawFilterTest < ActiveSupport::TestCase
  include DrawFactory

  setup do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ], date: Date.new(2020, 1, 2))
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ], date: Date.new(2020, 1, 3))
    create_draw(3, [ 10, 11, 12, 13, 14, 15 ], date: Date.new(2020, 2, 10))
  end

  def contests(params = {})
    DrawFilter.new(params).scope.pluck(:contest_number)
  end

  test "sem filtros devolve tudo, do mais recente ao mais antigo" do
    assert_equal [ 3, 2, 1 ], contests
  end

  test "ordem crescente" do
    assert_equal [ 1, 2, 3 ], contests(order: "asc")
  end

  test "filtra por período (inclusive nas bordas)" do
    assert_equal [ 2 ], contests(from: "2020-01-03", to: "2020-01-31")
    assert_equal [ 3, 2 ], contests(from: "2020-01-03")
    assert_equal [ 1 ], contests(to: "2020-01-02")
  end

  test "filtra por dezena" do
    assert_equal [ 2, 1 ], contests(number: 1)
    assert_equal [ 3 ], contests(number: "15")
    assert_equal [ 3, 2, 1 ], contests(number: 61)  # fora da faixa: ignorado
  end

  test "combina período e dezena" do
    assert_equal [ 1 ], contests(from: "2020-01-01", to: "2020-01-02", number: 1)
  end

  test "período invertido é inválido e não devolve nada" do
    filter = DrawFilter.new(from: "2020-02-01", to: "2020-01-01")

    assert_not filter.valid?
    assert_empty filter.scope
  end

  test "datas inválidas são ignoradas" do
    filter = DrawFilter.new(from: "32/13/2020", to: "abc")

    assert_nil filter.from
    assert_nil filter.to
    assert filter.valid?
  end

  test "paginação com valores padrão e limites" do
    assert_equal 25, DrawFilter.new.per_page
    assert_equal 50, DrawFilter.new(per: "50").per_page
    assert_equal 25, DrawFilter.new(per: "7").per_page
    assert_equal 1, DrawFilter.new(page: "-3").page
    assert_equal 4, DrawFilter.new(page: "4").page
  end

  test "aceita ActionController::Parameters" do
    filter = DrawFilter.new(ActionController::Parameters.new(from: "2020-01-03", number: "1"))

    assert_equal Date.new(2020, 1, 3), filter.from
    assert_equal 1, filter.number
  end

  test "to_params, filtered? e filename_suffix" do
    filter = DrawFilter.new(from: "2020-01-03", to: "2020-01-31", number: 7, order: "asc")

    assert_equal({ from: "2020-01-03", to: "2020-01-31", number: 7, order: "asc" }, filter.to_params)
    assert filter.filtered?
    assert_equal "de-2020-01-03_ate-2020-01-31_dezena-07", filter.filename_suffix

    assert_not DrawFilter.new.filtered?
    assert_empty DrawFilter.new.to_params
    assert_equal "", DrawFilter.new.filename_suffix
  end

  test "rótulo do período" do
    assert_equal "Todo o histórico", DrawFilter.new.period_label
    assert_includes DrawFilter.new(from: "2020-01-03").period_label, "2020"
  end
end
