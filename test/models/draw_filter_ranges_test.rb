require "test_helper"
require "support/draw_factory"

class DrawFilterRangesTest < ActiveSupport::TestCase
  include DrawFactory

  setup do
    # ganhadores da Sena por concurso: 1→0, 2→1, 3→0, 4→2, 5→0
    [ 0, 1, 0, 2, 0 ].each_with_index do |winners, index|
      create_draw(index + 1, [ 1, 2, 3, 4, 5, 6 ]).update!(winners_sena: winners)
    end
    create_draw(6, [ 7, 8, 9, 10, 11, 12 ])   # sem informação de ganhadores (nil)
  end

  def contests(params = {})
    DrawFilter.new(params).scope.pluck(:contest_number)
  end

  test "intervalo de concursos (inclusive)" do
    assert_equal [ 4, 3, 2 ], contests(contest_from: 2, contest_to: 4)
    assert_equal [ 6, 5, 4, 3, 2 ], contests(contest_from: "2")
    assert_equal [ 3, 2, 1 ], contests(contest_to: 3)
  end

  test "intervalo de ganhadores da Sena (inclusive)" do
    assert_equal [ 5, 3, 1 ], contests(winners_min: 0, winners_max: 0)
    assert_equal [ 5, 3, 1 ], contests(winners_max: 0)
    assert_equal [ 4, 2 ], contests(winners_min: 1)
    assert_equal [ 4, 2 ], contests(winners_min: 1, winners_max: 2)
    assert_equal [ 4 ], contests(winners_min: 2)
    assert_equal [ 2 ], contests(winners_min: 1, winners_max: 1)
  end

  test "concursos sem informação de ganhadores ficam de fora quando há filtro de ganhadores" do
    assert_not_includes contests(winners_min: 0), 6
    assert_includes contests, 6
  end

  test "combina intervalo de concursos e de ganhadores" do
    assert_equal [ 5, 3 ], contests(contest_from: 2, contest_to: 5, winners_min: 0, winners_max: 0)
  end

  test "intervalos invertidos são inválidos" do
    contest = DrawFilter.new(contest_from: 5, contest_to: 2)
    assert_not contest.valid?
    assert_match(/concurso inicial/, contest.error_message)
    assert_empty contest.scope

    winners = DrawFilter.new(winners_min: 3, winners_max: 1)
    assert_not winners.valid?
    assert_match(/ganhadores/, winners.error_message)
    assert_empty winners.scope

    dates = DrawFilter.new(from: "2020-02-01", to: "2020-01-01")
    assert_match(/data inicial/, dates.error_message)

    assert_nil DrawFilter.new(contest_from: 1, contest_to: 5).error_message
  end

  test "valores fora dos limites são ignorados, mas zero é válido para ganhadores" do
    filter = DrawFilter.new(contest_from: 0, contest_to: -3, winners_min: -1, winners_max: "0")

    assert_nil filter.contest_from
    assert_nil filter.contest_to
    assert_nil filter.winners_min
    assert_equal 0, filter.winners_max
    assert filter.filtered?
  end

  test "to_params, filename_suffix e critérios" do
    filter = DrawFilter.new(contest_from: 2, contest_to: 4, winners_min: 0, winners_max: 0)

    assert_equal({ contest_from: 2, contest_to: 4, winners_min: 0, winners_max: 0 }, filter.to_params)
    assert_equal "concursos-2-4_ganhadores-0-0", filter.filename_suffix
    assert_equal [ "Concursos 2 a 4", "Ganhadores da Sena: exatamente 0" ], filter.criteria
    assert_equal "Concursos 2 a 4 · Ganhadores da Sena: exatamente 0", filter.criteria_label
  end

  test "descrições de ganhadores" do
    assert_match(/1 ou mais/, DrawFilter.new(winners_min: 1).criteria_label)
    assert_match(/até 3/, DrawFilter.new(winners_max: 3).criteria_label)
    assert_match(/de 1 a 3/, DrawFilter.new(winners_min: 1, winners_max: 3).criteria_label)
    assert_match(/a partir do 10/, DrawFilter.new(contest_from: 10).criteria_label)
    assert_match(/até o 20/, DrawFilter.new(contest_to: 20).criteria_label)
    assert_equal "Todo o histórico", DrawFilter.new.criteria_label
  end
end
