require "test_helper"
require "support/draw_factory"

class DrawExtrasTest < ActiveSupport::TestCase
  include DrawFactory

  test "to_param usa o número do concurso" do
    draw = create_draw(3080, [ 1, 2, 3, 4, 5, 6 ])
    assert_equal "3080", draw.to_param
  end

  test "soma, pares e faixas" do
    draw = create_draw(1, [ 2, 11, 21, 22, 40, 60 ])

    assert_equal 156, draw.numbers_sum
    assert_equal 4, draw.even_count
    assert_equal [ 1, 1, 2, 1, 0, 1 ], draw.band_counts
  end

  test "ganhador da Sena" do
    draw = create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    assert_not draw.sena_winner?

    draw.update!(winners_sena: 2)
    assert draw.sena_winner?
  end
end
