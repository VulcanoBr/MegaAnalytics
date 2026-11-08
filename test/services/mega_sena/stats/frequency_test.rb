require "test_helper"
require "support/draw_factory"

class MegaSena::Stats::FrequencyTest < ActiveSupport::TestCase
  include DrawFactory

  setup do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ])
    create_draw(3, [ 1, 10, 11, 12, 13, 14 ])
    create_draw(4, [ 1, 2, 15, 16, 17, 18 ])
    @dataset = MegaSena::Stats::Dataset.load
    @frequency = MegaSena::Stats::Frequency.new(@dataset)
  end

  test "retorna 60 entradas com as contagens corretas" do
    assert_equal 60, @frequency.entries.size
    assert_equal 4, @frequency.entries.find { |e| e.number == 1 }.count
    assert_equal 3, @frequency.entries.find { |e| e.number == 2 }.count
    assert_equal 0, @frequency.entries.find { |e| e.number == 60 }.count
  end

  test "calcula percentuais" do
    one = @frequency.entries.find { |e| e.number == 1 }
    assert_in_delta 100.0, one.percent_of_draws, 0.001
    assert_in_delta 100.0 * 4 / 24, one.percent_of_numbers, 0.001
  end

  test "rankings" do
    assert_equal 1, @frequency.most_frequent(1).first.number
    assert_equal 4, @frequency.most_frequent(1).first.count
    assert_equal 0, @frequency.least_frequent(1).first.count
  end

  test "tempo desde a última aparição e intervalo médio" do
    three = @frequency.entries.find { |e| e.number == 3 }
    assert_equal 2, three.draws_since_last   # saiu no concurso 2; último é o 4
    assert_in_delta 1.0, three.average_gap, 0.001

    never = @frequency.entries.find { |e| e.number == 60 }
    assert_nil never.draws_since_last
  end

  test "janela dos últimos concursos" do
    window = MegaSena::Stats::Frequency.new(@dataset.window(2))
    assert_equal 2, window.entries.find { |e| e.number == 1 }.count
    assert_equal 0, window.entries.find { |e| e.number == 3 }.count
  end

  test "conjunto vazio não gera entradas" do
    assert_empty MegaSena::Stats::Frequency.new(MegaSena::Stats::Dataset.new([])).entries
  end
end
