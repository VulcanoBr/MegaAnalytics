require "test_helper"
require "support/draw_factory"

class MegaSena::Stats::CombinationFrequencyTest < ActiveSupport::TestCase
  include DrawFactory

  setup do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ])
    create_draw(3, [ 1, 2, 10, 11, 12, 13 ])
    @dataset = MegaSena::Stats::Dataset.load
    @pairs = MegaSena::Stats::CombinationFrequency.new(@dataset, size: 2)
    @triples = MegaSena::Stats::CombinationFrequency.new(@dataset, size: 3)
  end

  test "par mais frequente" do
    top = @pairs.top(1).first

    assert_equal [ 1, 2 ], top.numbers
    assert_equal 3, top.count
    assert_equal "01 – 02", top.label
    assert_equal 3, top.last_seen_contest
    assert_in_delta 100.0, top.percent_of_draws, 0.001
  end

  test "terno mais frequente" do
    top = @triples.top(1).first

    assert_equal [ 1, 2, 3 ], top.numbers
    assert_equal 2, top.count
  end

  test "totais possíveis e já ocorridos" do
    assert_equal 1770, @pairs.total_possible
    assert_equal 34_220, @triples.total_possible
    assert_equal 41, @pairs.distinct_seen
    assert_equal 59, @triples.distinct_seen
    assert_equal 1770 - 41, @pairs.never_seen
  end

  test "percentual esperado e razão sobre o esperado" do
    assert_in_delta 100.0 * 15 / 1770, @pairs.expected_percent, 0.0001
    assert_in_delta 100.0 * 20 / 34_220, @triples.expected_percent, 0.0001
    assert_in_delta 1770 / 15.0, @pairs.top(1).first.lift, 0.01
  end

  test "filtra por dezena" do
    results = @pairs.top(50, containing: 10)

    assert_equal 5, results.size           # 10 com 1, 2, 11, 12 e 13
    assert(results.all? { |r| r.numbers.include?(10) })
    assert_equal 59, @pairs.total_possible(containing: 10)
    assert_equal 5, @pairs.distinct_seen(containing: 10)
  end

  test "rejeita tamanho inválido" do
    assert_raises(ArgumentError) { MegaSena::Stats::CombinationFrequency.new(@dataset, size: 4) }
  end
end
