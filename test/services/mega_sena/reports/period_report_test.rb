require "test_helper"
require "support/draw_factory"

class MegaSena::Reports::PeriodReportTest < ActiveSupport::TestCase
  include DrawFactory

  setup do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ]).update!(
      winners_sena: 0, total_revenue: 1000, accumulated_sena: 7000
    )
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ]).update!(
      winners_sena: 2, prize_sena: 500, total_revenue: 3000, accumulated_sena: 0
    )
  end

  test "resumo financeiro" do
    financial = MegaSena::Reports::PeriodReport.new(Draw.all).financial

    assert_equal 4000, financial.total_revenue
    assert_equal 2000, financial.average_revenue
    assert_equal 1, financial.draws_with_sena_winner
    assert_equal 1, financial.draws_without_sena_winner
    assert_equal 1000, financial.total_sena_prizes
    assert_equal 2, financial.largest_sena_prize_draw.contest_number
    assert_equal 1, financial.largest_accumulated_draw.contest_number
  end

  test "análises estatísticas do período" do
    report = MegaSena::Reports::PeriodReport.new(DrawFilter.new.scope)

    assert_not report.empty?
    assert_equal 2, report.draws_count
    assert_equal 1, report.first_row.contest_number
    assert_equal 2, report.last_row.contest_number
    assert_equal 60, report.frequency.entries.size
    assert_equal 2, report.frequency.entries.find { |e| e.number == 1 }.count
    assert_equal 7, report.parity.size
    assert_equal 6, report.ranges.bands.size
    assert_equal 1, report.repetition.pairs_count
  end

  test "respeita o filtro de período" do
    report = MegaSena::Reports::PeriodReport.new(DrawFilter.new(from: "2020-01-03").scope)
    # create_draw usa 2020-01-01 + contest: concurso 1 = 02/01, concurso 2 = 03/01
    assert_equal 1, report.draws_count
    assert_equal 2, report.first_row.contest_number
  end

  test "período vazio" do
    report = MegaSena::Reports::PeriodReport.new(Draw.none)

    assert report.empty?
    assert_equal 0, report.financial.total_revenue
    assert_nil report.financial.largest_sena_prize_draw
  end
end
