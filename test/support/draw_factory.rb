module DrawFactory
  # Cria um concurso. Se a data não for informada, usa uma data sequencial a partir de 2020-01-01.
  def create_draw(contest, numbers, date: nil)
    attrs = { contest_number: contest, draw_date: date || (Date.new(2020, 1, 1) + contest) }
    Draw::NUMBER_COLUMNS.each_with_index { |column, index| attrs[column] = numbers.fetch(index) }
    Draw.create!(attrs)
  end
end
