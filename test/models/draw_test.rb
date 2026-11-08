require "test_helper"

class DrawTest < ActiveSupport::TestCase
  def valid_attributes(overrides = {})
    {
      contest_number: 1, draw_date: Date.new(2020, 1, 4),
      number_1: 4, number_2: 12, number_3: 23, number_4: 35, number_5: 41, number_6: 58
    }.merge(overrides)
  end

  test "é válido com dados mínimos" do
    assert Draw.new(valid_attributes).valid?
  end

  test "rejeita dezenas repetidas" do
    draw = Draw.new(valid_attributes(number_2: 4))
    assert_not draw.valid?
  end

  test "rejeita dezena fora do intervalo 1..60" do
    assert_not Draw.new(valid_attributes(number_6: 61)).valid?
    assert_not Draw.new(valid_attributes(number_1: 0)).valid?
  end

  test "rejeita concurso duplicado" do
    Draw.create!(valid_attributes)
    assert_not Draw.new(valid_attributes).valid?
  end

  test "rejeita valor monetário negativo" do
    assert_not Draw.new(valid_attributes(prize_sena: -1)).valid?
  end

  test "o banco também impede dezenas repetidas" do
    draw = Draw.new(valid_attributes(number_2: 4))
    assert_raises(ActiveRecord::StatementInvalid) { draw.save!(validate: false) }
  end

  test "sorted_numbers devolve as dezenas ordenadas" do
    draw = Draw.new(valid_attributes(number_1: 58, number_6: 4))
    assert_equal draw.numbers.sort, draw.sorted_numbers
  end
end
