class Draw < ApplicationRecord
  NUMBER_COLUMNS = %i[number_1 number_2 number_3 number_4 number_5 number_6].freeze
  MONEY_COLUMNS = %i[
    prize_sena prize_quina prize_quadra accumulated_sena
    total_revenue estimated_prize special_draw_accumulated
  ].freeze
  COUNT_COLUMNS = %i[winners_sena winners_quina winners_quadra].freeze

  belongs_to :import_batch, optional: true

  validates :contest_number, presence: true,
                             numericality: { only_integer: true, greater_than: 0 },
                             uniqueness: true
  validates :draw_date, presence: true

  NUMBER_COLUMNS.each do |column|
    validates column, presence: true,
                      numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 60 }
  end

  validates(*MONEY_COLUMNS, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true)
  validates(*COUNT_COLUMNS, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true)

  validate :numbers_must_be_distinct

  scope :chronological, -> { order(:contest_number) }

  # URLs usam o número do concurso: /draws/3080
  def to_param
    contest_number&.to_s
  end

  # Dezenas na ordem em que foram importadas
  def numbers
    NUMBER_COLUMNS.map { |column| self[column] }
  end

  def sorted_numbers
    numbers.compact.sort
  end

  def numbers_sum
    numbers.compact.sum
  end

  def even_count
    numbers.compact.count(&:even?)
  end

  # Quantas dezenas caíram em cada faixa (padrão: 6 faixas de 10).
  def band_counts(band_size = 10)
    Array.new(60 / band_size, 0).tap do |counts|
      numbers.compact.each { |number| counts[(number - 1) / band_size] += 1 }
    end
  end

  def sena_winner?
    winners_sena.to_i.positive?
  end

  private

  def numbers_must_be_distinct
    present = numbers.compact
    errors.add(:base, "As seis dezenas devem ser distintas") if present.uniq.size != present.size
  end
end
