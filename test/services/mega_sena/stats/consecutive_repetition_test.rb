require "test_helper"
require "support/draw_factory"

class MegaSena::Stats::ConsecutiveRepetitionTest < ActiveSupport::TestCase
  include DrawFactory

  setup do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ])     # repete 1 2 3
    create_draw(3, [ 1, 2, 10, 11, 12, 13 ]) # repete 1 2
    @repetition = MegaSena::Stats::ConsecutiveRepetition.new(MegaSena::Stats::Dataset.load)
  end

  test "distribuição observada" do
    distribution = @repetition.distribution

    assert_equal 2, @repetition.pairs_count
    assert_equal 1, distribution.find { |b| b.repeated == 3 }.count
    assert_equal 1, distribution.find { |b| b.repeated == 2 }.count
    assert_equal 0, distribution.find { |b| b.repeated == 0 }.count
    assert_in_delta 100.0, distribution.sum(&:percent), 0.001
  end

  test "percentuais esperados somam 100 e média esperada é 0,6" do
    distribution = @repetition.distribution

    assert_in_delta 100.0, distribution.sum(&:expected_percent), 0.001
    assert_in_delta 0.6, distribution.sum { |b| b.repeated * b.expected_percent / 100 }, 0.001
    assert_in_delta 0.6, @repetition.expected_mean, 0.001
  end

  test "média de dezenas repetidas" do
    assert_in_delta 2.5, @repetition.mean_repeated, 0.001
  end

  test "taxa de repetição por dezena" do
    rates = @repetition.number_rates(60).index_by(&:number)

    assert_equal 2, rates[1].opportunities
    assert_equal 2, rates[1].repeats
    assert_in_delta 100.0, rates[1].rate, 0.001
    assert_equal 0, rates[4].repeats
    assert_equal 1, rates[3].repeats
  end

  test "repetições recentes" do
    recent = @repetition.recent(1).first

    assert_equal 3, recent.contest_number
    assert_equal 2, recent.previous_contest
    assert_equal [ 1, 2 ], recent.repeated
  end

  test "com um único concurso não há pares" do
    single = MegaSena::Stats::ConsecutiveRepetition.new(MegaSena::Stats::Dataset.load.window(1))

    assert single.empty?
    assert_nil single.mean_repeated
  end

  test "ignora concursos não consecutivos" do
    Draw.where(contest_number: 2).delete_all
    repetition = MegaSena::Stats::ConsecutiveRepetition.new(MegaSena::Stats::Dataset.load)

    assert repetition.empty?
  end
end
