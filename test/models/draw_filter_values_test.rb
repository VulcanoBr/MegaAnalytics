require "test_helper"
require "support/draw_factory"

class DrawFilterValuesTest < ActiveSupport::TestCase
  include DrawFactory

  setup do
    # concurso: prêmio da Sena (rateio) / estimativa
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ]).update!(winners_sena: 1, prize_sena: 45_000_000, estimated_prize: 50_000_000)
    create_draw(2, [ 1, 2, 3, 4, 5, 6 ]).update!(winners_sena: 1, prize_sena: 55_000_000, estimated_prize: 60_000_000)
    create_draw(3, [ 1, 2, 3, 4, 5, 6 ]).update!(winners_sena: 1, prize_sena: 60_000_000, estimated_prize: 3_000_000)
    create_draw(4, [ 1, 2, 3, 4, 5, 6 ]).update!(winners_sena: 0, estimated_prize: 52_000_000)   # sem prize_sena
    create_draw(5, [ 1, 2, 3, 4, 5, 6 ]).update!(winners_sena: 3, prize_sena: 100_000_000, estimated_prize: 61_000_000)
  end

  def contests(params = {})
    DrawFilter.new(params).scope.pluck(:contest_number)
  end

  test "intervalo de valor do prêmio da Sena (campo padrão, inclusive nas bordas)" do
    assert_equal [ 3, 2 ], contests(value_min: 50_000_000, value_max: 60_000_000)
  end

  test "outro campo: estimativa de prêmio" do
    assert_equal [ 4, 2, 1 ], contests(value_field: "estimated_prize", value_min: 50_000_000, value_max: 60_000_000)
  end

  test "apenas mínimo ou apenas máximo" do
    assert_equal [ 5, 3 ], contests(value_min: 60_000_000)
    assert_equal [ 1 ], contests(value_max: 45_000_000)
  end

  test "concursos sem o valor ficam de fora" do
    assert_not_includes contests(value_min: 0), 4
    assert_includes contests(value_field: "estimated_prize", value_min: 0), 4
  end

  test "aceita números digitados no padrão brasileiro" do
    expected = [ 3, 2 ]
    assert_equal expected, contests(value_min: "50.000.000,00", value_max: "60.000.000,00")
    assert_equal expected, contests(value_min: "R$ 50.000.000", value_max: "60000000")
    assert_equal expected, contests(value_min: "50000000.00", value_max: "60000000.00")
  end

  test "interpretação de valores digitados" do
    parse = ->(text) { DrawFilter.new(value_min: text).value_min }

    assert_equal 50_000_000, parse.call("50.000.000,00")
    assert_equal 50_000_000, parse.call("50.000.000")
    assert_equal 50_000_000, parse.call("50000000")
    assert_equal BigDecimal("50000000.5"), parse.call("50000000.5")
    assert_equal BigDecimal("1234.56"), parse.call("R$ 1.234,56")
    assert_equal BigDecimal("1.5"), parse.call("1,5")
    assert_equal 0, parse.call("0")
    assert_nil parse.call("")
    assert_nil parse.call("abc")
    assert_nil parse.call("-5")
    assert_nil parse.call("12abc")
  end

  test "campo desconhecido volta ao padrão" do
    filter = DrawFilter.new(value_field: "id; DROP TABLE draws", value_min: 1)

    assert_equal "prize_sena", filter.value_field
    assert_nothing_raised { filter.scope.to_a }
  end

  test "valor mínimo maior que o máximo é inválido" do
    filter = DrawFilter.new(value_min: 60_000_000, value_max: 50_000_000)

    assert_not filter.valid?
    assert_match(/valor mínimo/, filter.error_message)
    assert_empty filter.scope
  end

  test "combina com ganhadores e intervalo de concursos" do
    assert_equal [ 5 ], contests(value_min: 60_000_000, winners_min: 3)
    assert_equal [ 3 ], contests(value_min: 50_000_000, value_max: 60_000_000, contest_from: 3)
  end

  test "to_params, filename_suffix, filtered? e critérios" do
    filter = DrawFilter.new(value_field: "estimated_prize", value_min: "50.000.000,00", value_max: "60.000.000,00")

    assert_equal(
      { value_field: "estimated_prize", value_min: "50000000.00", value_max: "60000000.00" },
      filter.to_params
    )
    assert_equal "valor-estimativa-50000000-60000000", filter.filename_suffix
    assert filter.filtered?
    assert_match(/Estimativa de prêmio: de .*50[.,]000[.,]000.* a .*60[.,]000[.,]000/, filter.criteria_label)

    # o próprio to_params, relido, produz o mesmo filtro
    again = DrawFilter.new(filter.to_params)
    assert_equal filter.value_min, again.value_min
    assert_equal filter.value_max, again.value_max
    assert_equal filter.value_field, again.value_field
  end

  test "sem valores, o campo não entra nos parâmetros" do
    filter = DrawFilter.new(value_field: "estimated_prize")

    assert_empty filter.to_params
    assert_not filter.filtered?
    assert_equal "", filter.filename_suffix
  end

  test "descrições de mínimo e máximo isolados" do
    assert_match(/a partir de/, DrawFilter.new(value_min: 1_000).criteria_label)
    assert_match(/até/, DrawFilter.new(value_max: 1_000).criteria_label)
    assert_match(/Prêmio da Sena/, DrawFilter.new(value_min: 1_000).criteria_label)
  end
end
