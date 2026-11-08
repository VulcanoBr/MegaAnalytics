require "test_helper"

class MegaSena::Stats::FrequencyRangesTest < ActiveSupport::TestCase
  Row = MegaSena::Stats::Row

  def dataset(*rows)
    MegaSena::Stats::Dataset.new(rows.map { |contest, numbers| Row.new(contest_number: contest, draw_date: Date.new(2020, 1, 1), numbers: numbers) })
  end

  test "concursos após a última aparição em conjunto contíguo" do
    entries = MegaSena::Stats::Frequency.new(
      dataset([ 1, [ 1, 2, 3, 4, 5, 6 ] ], [ 2, [ 1, 2, 3, 7, 8, 9 ] ], [ 3, [ 10, 11, 12, 13, 14, 15 ] ])
    ).entries.index_by(&:number)

    assert_equal 1, entries[1].draws_after_last     # saiu nos concursos 1 e 2; falta o 3
    assert_equal 2, entries[4].draws_after_last     # só no concurso 1
    assert_equal 0, entries[10].draws_after_last    # saiu no último
    assert_nil entries[60].draws_after_last         # nunca saiu
    assert_equal entries[1].draws_since_last, entries[1].draws_after_last
  end

  test "em conjunto não contíguo conta concursos encontrados, não números de concurso" do
    data = dataset([ 10, [ 1, 2, 3, 4, 5, 6 ] ], [ 20, [ 1, 2, 3, 7, 8, 9 ] ], [ 30, [ 10, 11, 12, 13, 14, 15 ] ])
    entries = MegaSena::Stats::Frequency.new(data).entries.index_by(&:number)

    assert_not data.contiguous?
    assert_equal 1, entries[1].draws_after_last      # só o concurso 30 veio depois
    assert_equal 10, entries[1].draws_since_last     # 30 - 20
    assert_equal 2, entries[4].draws_after_last
    assert_equal 20, entries[4].draws_since_last
    assert_equal 2, entries[1].count
    assert_equal 20, entries[1].last_seen_contest
  end

  test "contiguous?" do
    assert dataset([ 1, [ 1, 2, 3, 4, 5, 6 ] ], [ 2, [ 1, 2, 3, 4, 5, 6 ] ]).contiguous?
    assert dataset.contiguous?
    assert_not dataset([ 1, [ 1, 2, 3, 4, 5, 6 ] ], [ 3, [ 1, 2, 3, 4, 5, 6 ] ]).contiguous?
  end
end
