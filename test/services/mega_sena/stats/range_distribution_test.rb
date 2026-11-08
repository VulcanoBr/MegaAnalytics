require "test_helper"
require "support/draw_factory"

class MegaSena::Stats::RangeDistributionTest < ActiveSupport::TestCase
  include DrawFactory

  setup do
    create_draw(1, [ 1, 2, 3, 11, 12, 21 ])    # faixas: 3, 2, 1, 0, 0, 0
    create_draw(2, [ 1, 11, 21, 31, 41, 51 ])  # uma dezena em cada faixa
    @ranges = MegaSena::Stats::RangeDistribution.new(MegaSena::Stats::Dataset.load)
  end

  test "faixas de 10" do
    bands = @ranges.bands

    assert_equal 6, bands.size
    assert_equal "01–10", bands.first.label
    assert_equal "51–60", bands.last.label
    assert_equal [ 4, 3, 2, 1, 1, 1 ], bands.map(&:occurrences)
    assert_in_delta 100.0, bands.sum(&:percent_of_numbers), 0.001
    assert_in_delta 100.0 * 4 / 12, bands.first.percent_of_numbers, 0.001
    assert_in_delta 2.0, bands.first.mean_per_draw, 0.001
  end

  test "concursos sem dezena na faixa" do
    band = @ranges.bands[3]   # 31–40

    assert_equal 1, band.empty_draws
    assert_in_delta 50.0, band.empty_percent, 0.001
    assert_equal 0, @ranges.bands.first.empty_draws
  end

  test "valores esperados" do
    assert_equal 6, @ranges.band_count
    assert_in_delta 16.667, @ranges.expected_percent_of_numbers, 0.001
    assert_in_delta 1.0, @ranges.expected_mean_per_draw, 0.001
    assert_in_delta 31.74, @ranges.expected_empty_percent, 0.01
  end

  test "perfis de distribuição" do
    profiles = @ranges.profiles

    assert_equal 11, profiles.size
    assert_in_delta 100.0, profiles.sum(&:percent), 0.001
    assert_in_delta 100.0, profiles.sum(&:expected_percent), 0.001
    assert_equal 1, profiles.find { |p| p.pattern == [ 3, 2, 1 ] }.count
    assert_equal 1, profiles.find { |p| p.pattern == [ 1, 1, 1, 1, 1, 1 ] }.count
    assert_equal "3-2-1", profiles.find { |p| p.pattern == [ 3, 2, 1 ] }.label
    assert_in_delta 100.0 * 1_000_000 / 50_063_860,
                    profiles.find { |p| p.pattern == [ 1, 1, 1, 1, 1, 1 ] }.expected_percent, 0.0001
  end

  test "rejeita faixa que não divide 60" do
    assert_raises(ArgumentError) { MegaSena::Stats::RangeDistribution.new(MegaSena::Stats::Dataset.new([]), band_size: 7) }
  end
end
