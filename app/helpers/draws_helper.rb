module DrawsHelper
  def draw_ball(number)
    content_tag(:span, two_digits(number),
                class: "inline-flex h-8 w-8 items-center justify-center rounded-full bg-emerald-600 text-sm font-semibold text-white")
  end

  def draw_balls(numbers)
    content_tag(:div, safe_join(numbers.map { |n| draw_ball(n) }), class: "flex gap-1")
  end

  # Valor para campos de formulário no padrão pt-BR: 50.000.000,00
  def money_input(value)
    value.nil? ? nil : number_with_precision(value, precision: 2, delimiter: ".", separator: ",")
  end

  def value_field_options
    DrawFilter::VALUE_FIELDS.map { |key, label| [ label, key ] }
  end

  def money(value)
    value.nil? ? "—" : number_to_currency(value)
  end

  # [rótulo, parâmetros de período] para atalhos de filtro.
  def period_presets
    today = Date.current
    last_year = today - 1.year

    [
      [ "Todo o histórico", {} ],
      [ "Últimos 12 meses", { from: (today - 1.year).iso8601, to: today.iso8601 } ],
      [ "Este ano", { from: today.beginning_of_year.iso8601, to: today.iso8601 } ],
      [ "Ano passado", { from: last_year.beginning_of_year.iso8601, to: last_year.end_of_year.iso8601 } ],
      [ "Últimos 5 anos", { from: (today - 5.years).iso8601, to: today.iso8601 } ]
    ]
  end

  def preset_active?(filter, range)
    filter.from&.iso8601 == range[:from] && filter.to&.iso8601 == range[:to] && filter.number.nil?
  end
end
