# Filtros compartilhados por listagem de concursos, relatório, frequência e exportações.
# Aceita Hash ou ActionController::Parameters.
#
# Critérios (todos opcionais e combináveis):
#   from / to                  — período (datas ISO, inclusive)
#   contest_from / contest_to  — intervalo de números de concurso (inclusive)
#   winners_min / winners_max  — intervalo de ganhadores da Sena (inclusive)
#   value_field + value_min / value_max — intervalo de valor em R$ (inclusive) de um dos campos de VALUE_FIELDS
#   number                     — concursos que contêm a dezena
class DrawFilter
  PER_PAGE_OPTIONS = [ 25, 50, 100 ].freeze

  # Campo monetário ao qual o intervalo de valor se aplica (padrão: o primeiro).
  VALUE_FIELDS = {
    "prize_sena" => "Prêmio da Sena (rateio por ganhador)",
    "estimated_prize" => "Estimativa de prêmio",
    "accumulated_sena" => "Acumulado da Sena",
    "total_revenue" => "Arrecadação total"
  }.freeze

  VALUE_FIELD_SLUGS = {
    "prize_sena" => "premio-sena",
    "estimated_prize" => "estimativa",
    "accumulated_sena" => "acumulado",
    "total_revenue" => "arrecadacao"
  }.freeze

  attr_reader :from, :to, :number, :contest_from, :contest_to, :winners_min, :winners_max,
              :value_field, :value_min, :value_max, :order, :per_page, :page

  def initialize(params = {})
    params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
    params = (params || {}).to_h.with_indifferent_access

    @from = parse_date(params[:from])
    @to = parse_date(params[:to])

    number = Integer(params[:number], exception: false)
    @number = number if number&.between?(1, 60)

    @contest_from = parse_integer(params[:contest_from], minimum: 1)
    @contest_to = parse_integer(params[:contest_to], minimum: 1)
    @winners_min = parse_integer(params[:winners_min], minimum: 0)
    @winners_max = parse_integer(params[:winners_max], minimum: 0)

    @value_field = VALUE_FIELDS.key?(params[:value_field].to_s) ? params[:value_field].to_s : VALUE_FIELDS.keys.first
    @value_min = parse_money(params[:value_min])
    @value_max = parse_money(params[:value_max])

    @order = params[:order].to_s == "asc" ? :asc : :desc
    @per_page = PER_PAGE_OPTIONS.include?(params[:per].to_i) ? params[:per].to_i : PER_PAGE_OPTIONS.first
    @page = [ params[:page].to_i, 1 ].max
  end

  # Mensagem do primeiro problema encontrado nos critérios (nil se estiver tudo certo).
  def error_message
    return "A data inicial não pode ser posterior à data final." if from && to && from > to
    return "O concurso inicial não pode ser maior que o concurso final." if contest_from && contest_to && contest_from > contest_to
    return "O mínimo de ganhadores não pode ser maior que o máximo." if winners_min && winners_max && winners_min > winners_max
    return "O valor mínimo não pode ser maior que o valor máximo." if value_min && value_max && value_min > value_max

    nil
  end

  def valid?
    error_message.nil?
  end

  def filtered?
    [ from, to, number, contest_from, contest_to, winners_min, winners_max, value_min, value_max ].any?(&:present?) ||
      [ winners_min, winners_max, value_min, value_max ].any? { |value| value == 0 }
  end

  def scope
    return Draw.none unless valid?

    relation = Draw.all
    relation = relation.where(draw_date: from..) if from
    relation = relation.where(draw_date: ..to) if to
    relation = relation.where(contest_number: contest_from..) if contest_from
    relation = relation.where(contest_number: ..contest_to) if contest_to
    relation = relation.where(winners_sena: winners_min..) if winners_min
    relation = relation.where(winners_sena: ..winners_max) if winners_max
    relation = relation.where(value_field => value_min..) if value_min
    relation = relation.where(value_field => ..value_max) if value_max
    if number
      condition = Draw::NUMBER_COLUMNS.map { |column| "#{column} = :number" }.join(" OR ")
      relation = relation.where(condition, number: number)
    end
    relation.order(contest_number: order)
  end

  # Parâmetros de URL para preservar o filtro em links e exportações.
  def to_params
    {
      from: from&.iso8601,
      to: to&.iso8601,
      contest_from: contest_from,
      contest_to: contest_to,
      winners_min: winners_min,
      winners_max: winners_max,
      value_field: (value_field if value_min || value_max),
      value_min: money_param(value_min),
      value_max: money_param(value_max),
      number: number,
      order: (order == :asc ? "asc" : nil)
    }.compact
  end

  def period_label
    return "Todo o histórico" unless from || to

    start = from ? I18n.l(from) : "início"
    finish = to ? I18n.l(to) : "hoje"
    "#{start} a #{finish}"
  end

  # Lista legível dos critérios aplicados.
  def criteria
    items = []
    items << "Período: #{period_label}" if from || to
    items << contests_description if contest_from || contest_to
    items << winners_description if winners_min || winners_max
    items << value_description if value_min || value_max
    items << "Contendo a dezena #{format('%02d', number)}" if number
    items
  end

  def criteria_label
    criteria.empty? ? "Todo o histórico" : criteria.join(" · ")
  end

  def filename_suffix
    parts = []
    parts << "de-#{from.iso8601}" if from
    parts << "ate-#{to.iso8601}" if to
    parts << "concursos-#{contest_from || 'inicio'}-#{contest_to || 'fim'}" if contest_from || contest_to
    parts << "ganhadores-#{winners_min || 'min'}-#{winners_max || 'max'}" if winners_min || winners_max
    parts << "valor-#{VALUE_FIELD_SLUGS[value_field]}-#{value_min&.to_i || 'min'}-#{value_max&.to_i || 'max'}" if value_min || value_max
    parts << "dezena-#{format('%02d', number)}" if number
    parts.join("_")
  end

  private

  def contests_description
    if contest_from && contest_to
      "Concursos #{contest_from} a #{contest_to}"
    elsif contest_from
      "Concursos a partir do #{contest_from}"
    else
      "Concursos até o #{contest_to}"
    end
  end

  def value_description
    label = VALUE_FIELDS[value_field]
    if value_min && value_max
      "#{label}: de #{currency(value_min)} a #{currency(value_max)}"
    elsif value_min
      "#{label}: a partir de #{currency(value_min)}"
    else
      "#{label}: até #{currency(value_max)}"
    end
  end

  def currency(value)
    ActiveSupport::NumberHelper.number_to_currency(value)
  end

  # "50000000.00" — duas casas decimais, sem separador de milhar (não se confunde com o formato pt-BR).
  def money_param(value)
    value && format("%.2f", value)
  end

  def winners_description
    if winners_min && winners_max
      winners_min == winners_max ? "Ganhadores da Sena: exatamente #{winners_min}" : "Ganhadores da Sena: de #{winners_min} a #{winners_max}"
    elsif winners_min
      "Ganhadores da Sena: #{winners_min} ou mais"
    else
      "Ganhadores da Sena: até #{winners_max}"
    end
  end

  def parse_date(value)
    return nil if value.blank?

    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  # Aceita "50.000.000,00", "R$ 50.000.000", "50000000", "50000000.50" ou número. Devolve BigDecimal >= 0 ou nil.
  def parse_money(value)
    return nil if value.blank?

    decimal = value.is_a?(Numeric) ? BigDecimal(value.to_s) : parse_money_string(value.to_s)
    decimal if decimal && decimal >= 0
  end

  def parse_money_string(text)
    cleaned = text.gsub(/R\$|\s/, "")
    cleaned =
      if cleaned.include?(",")
        cleaned.delete(".").tr(",", ".")
      elsif cleaned.match?(/\A\d{1,3}(\.\d{3})+\z/)
        cleaned.delete(".")
      else
        cleaned
      end
    BigDecimal(cleaned)
  rescue ArgumentError
    nil
  end

  def parse_integer(value, minimum:)
    integer = Integer(value, exception: false)
    integer if integer && integer >= minimum
  end
end
