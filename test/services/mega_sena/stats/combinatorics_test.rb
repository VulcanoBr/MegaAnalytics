require "test_helper"

class MegaSena::Stats::CombinatoricsTest < ActiveSupport::TestCase
  C = MegaSena::Stats::Combinatorics

  test "binomial" do
    assert_equal 50_063_860, C.binom(60, 6)
    assert_equal 1770, C.binom(60, 2)
    assert_equal 0, C.binom(3, 5)
  end

  test "pares consecutivos: probabilidades somam 1 e a média é 0,5" do
    probabilities = (0..5).map { |k| C.probability_of_adjacent_pairs(k) }

    assert_in_delta 1.0, probabilities.sum, 1e-9
    assert_in_delta 0.5, probabilities.each_with_index.sum { |p, k| p * k }, 1e-9
    assert_in_delta 0.579, probabilities.first, 0.001
    assert_in_delta 55.0 / 50_063_860, probabilities.last, 1e-12
  end

  test "perfis de faixas: 11 padrões e probabilidades somam 1" do
    profiles = C.band_profile_probabilities(band_size: 10)

    assert_equal 11, profiles.size
    assert_in_delta 1.0, profiles.values.sum, 1e-9
    assert_in_delta 1_000_000.0 / 50_063_860, profiles[[ 1, 1, 1, 1, 1, 1 ]], 1e-12
  end

  test "faixa vazia" do
    assert_in_delta 15_890_700.0 / 50_063_860, C.probability_of_empty_band(10), 1e-9
  end

  test "composições" do
    assert_equal 462, C.compositions(6, 6).size
    assert_equal [ [ 3 ] ], C.compositions(3, 1)
  end
end
