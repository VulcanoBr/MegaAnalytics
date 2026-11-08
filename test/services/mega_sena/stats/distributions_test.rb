require "test_helper"
require "support/draw_factory"

class MegaSena::Stats::DistributionsTest < ActiveSupport::TestCase
  include DrawFactory

  setup do
    create_draw(1, [ 2, 4, 6, 8, 10, 12 ])      # 6 pares, soma 42
    create_draw(2, [ 1, 3, 5, 7, 9, 11 ])       # 0 pares, soma 36
    create_draw(3, [ 1, 2, 3, 4, 5, 6 ])        # 3 pares, soma 21
    create_draw(4, [ 10, 20, 30, 40, 50, 60 ])  # 6 pares, soma 210
    @dataset = MegaSena::Stats::Dataset.load
  end

  test "distribuição de pares e ímpares" do
    buckets = MegaSena::Stats::ParityDistribution.new(@dataset).call

    assert_equal 7, buckets.size
    assert_equal 2, buckets.find { |b| b.evens == 6 }.count
    assert_equal 1, buckets.find { |b| b.evens == 0 }.count
    assert_equal 1, buckets.find { |b| b.evens == 3 }.count
    assert_in_delta 100.0, buckets.sum(&:percent), 0.001
  end

  test "estatísticas e faixas da soma" do
    sums = MegaSena::Stats::SumDistribution.new(@dataset)

    assert_equal 21, sums.min
    assert_equal 210, sums.max
    assert_in_delta 77.25, sums.mean, 0.001
    assert_in_delta 39.0, sums.median, 0.001

    buckets = sums.buckets
    assert_equal 20, buckets.first.from
    assert_equal 200, buckets.last.from
    assert_equal 4, buckets.sum(&:count)
    assert_equal 2, buckets.find { |b| b.from == 20 }.count   # 21 e 36
    assert_equal 0, buckets.find { |b| b.from == 100 }.count  # faixas vazias preenchidas
  end

  test "evolução da frequência por bloco" do
    points = MegaSena::Stats::Evolution.new(@dataset, number: 1, block_size: 2).call

    assert_equal 2, points.size
    assert_equal "1–2", points.first.label
    assert_in_delta 50.0, points.first.percent, 0.001   # só o concurso 2 tem a dezena 1
    assert_in_delta 50.0, points.last.percent, 0.001    # só o concurso 3
  end

  test "comparação de período com o histórico" do
    window = MegaSena::Stats::Frequency.new(@dataset.window(2)).entries
    all = MegaSena::Stats::Frequency.new(@dataset).entries
    comparison = MegaSena::Stats::PeriodComparison.new(window, all)

    row = comparison.rows.find { |r| r.number == 60 }
    assert_in_delta 50.0, row.window_percent, 0.001
    assert_in_delta 25.0, row.all_percent, 0.001
    assert_in_delta 25.0, row.delta, 0.001
    assert_in_delta 25.0, comparison.rising(1).first.delta, 0.001
  end
end
