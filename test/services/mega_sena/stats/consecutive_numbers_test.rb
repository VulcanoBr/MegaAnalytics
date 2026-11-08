require "test_helper"
require "support/draw_factory"

class MegaSena::Stats::ConsecutiveNumbersTest < ActiveSupport::TestCase
  include DrawFactory

  setup do
    create_draw(1, [ 1, 2, 3, 10, 20, 30 ])     # sequência 1-2-3 → 2 pares
    create_draw(2, [ 5, 6, 20, 30, 40, 50 ])    # 5-6 → 1 par
    create_draw(3, [ 1, 10, 20, 30, 40, 50 ])   # nenhuma
    create_draw(4, [ 11, 12, 13, 14, 15, 16 ])  # 11..16 → 5 pares
    @consecutive = MegaSena::Stats::ConsecutiveNumbers.new(MegaSena::Stats::Dataset.load)
  end

  test "identifica sequências" do
    assert_equal [ [ 1, 2, 3 ] ], MegaSena::Stats::ConsecutiveNumbers.runs([ 3, 1, 2, 10, 20, 30 ])
    assert_equal [ [ 12, 13 ], [ 40, 41, 42 ] ], MegaSena::Stats::ConsecutiveNumbers.runs([ 42, 12, 40, 13, 41, 5 ])
    assert_empty MegaSena::Stats::ConsecutiveNumbers.runs([ 1, 3, 5, 7, 9, 11 ])
  end

  test "distribuição de pares consecutivos" do
    distribution = @consecutive.distribution

    assert_equal 6, distribution.size
    assert_equal 1, distribution.find { |b| b.pairs == 0 }.count
    assert_equal 1, distribution.find { |b| b.pairs == 1 }.count
    assert_equal 1, distribution.find { |b| b.pairs == 2 }.count
    assert_equal 1, distribution.find { |b| b.pairs == 5 }.count
    assert_in_delta 100.0, distribution.sum(&:percent), 0.001
    assert_in_delta 100.0, distribution.sum(&:expected_percent), 0.001
  end

  test "média e percentual com sequência" do
    assert_in_delta 2.0, @consecutive.mean_pairs, 0.001
    assert_equal 3, @consecutive.draws_with_sequence
    assert_in_delta 75.0, @consecutive.percent_with_sequence, 0.001
    assert_in_delta 42.1, @consecutive.expected_percent_with_sequence, 0.1
  end

  test "maior sequência" do
    longest = @consecutive.longest

    assert_equal 4, longest.contest_number
    assert_equal [ [ 11, 12, 13, 14, 15, 16 ] ], longest.sequences
  end

  test "pares consecutivos mais frequentes" do
    pairs = @consecutive.top_adjacent_pairs(20)

    assert_equal 8, pairs.size                # 2 + 1 + 5
    assert(pairs.all? { |p| p.count == 1 })
    assert_equal "01 – 02", pairs.first.label
  end

  test "sequências recentes" do
    recent = @consecutive.recent(3)

    assert_equal [ 4, 2, 1 ], recent.map(&:contest_number)
    assert_equal [ [ 5, 6 ] ], recent[1].sequences
  end

  test "sem sequências" do
    Draw.delete_all
    create_draw(1, [ 1, 3, 5, 7, 9, 11 ])
    consecutive = MegaSena::Stats::ConsecutiveNumbers.new(MegaSena::Stats::Dataset.load)

    assert_nil consecutive.longest
    assert_empty consecutive.top_adjacent_pairs
    assert_empty consecutive.recent
    assert_in_delta 0.0, consecutive.percent_with_sequence, 0.001
  end
end
