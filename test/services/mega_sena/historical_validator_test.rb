require "test_helper"

class MegaSena::HistoricalValidatorTest < ActiveSupport::TestCase
  def create_draw(contest, date, numbers = [ 1, 2, 3, 4, 5, 6 ], **extra)
    attrs = { contest_number: contest, draw_date: date }
    Draw::NUMBER_COLUMNS.each_with_index { |col, i| attrs[col] = numbers[i] }
    Draw.create!(attrs.merge(extra))
  end

  test "histórico íntegro resulta em passed" do
    create_draw(1, Date.new(2020, 1, 4))
    create_draw(2, Date.new(2020, 1, 8))

    report = MegaSena::HistoricalValidator.new.call

    assert_equal "passed", report["result"]
    assert_equal 2, report["checked_draws"]
  end

  test "lacuna na sequência resulta em failed" do
    create_draw(1, Date.new(2020, 1, 4))
    create_draw(3, Date.new(2020, 1, 11))

    report = MegaSena::HistoricalValidator.new.call

    assert_equal "failed", report["result"]
    assert_includes report["errors"].map { |e| e["code"] }, "gap"
  end

  test "ordem cronológica invertida resulta em failed" do
    create_draw(1, Date.new(2020, 1, 11))
    create_draw(2, Date.new(2020, 1, 4))

    report = MegaSena::HistoricalValidator.new.call

    assert_includes report["errors"].map { |e| e["code"] }, "chronology"
  end

  test "histórico que não começa no concurso 1 gera aviso" do
    create_draw(10, Date.new(2020, 1, 4))

    report = MegaSena::HistoricalValidator.new.call

    assert_equal "warning", report["result"]
  end
end
