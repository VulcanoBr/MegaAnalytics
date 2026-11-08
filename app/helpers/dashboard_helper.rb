module DashboardHelper
  def percent(value, digits = 1)
    return "—" if value.nil?

    "#{number_with_precision(value, precision: digits)}%"
  end

  def signed_percent(value, digits = 1)
    sign = value.positive? ? "+" : ""
    "#{sign}#{number_with_precision(value, precision: digits)} p.p."
  end

  def two_digits(number)
    format("%02d", number)
  end

  def window_label(key)
    key == "all" ? "Todo o histórico" : "Últimos #{key}"
  end

  def horizontal_bar(label:, value:, max:, caption:, color: "bg-emerald-500")
    width = max.to_f.zero? ? 0 : (value.to_f / max * 100).round(1)

    content_tag(:div, class: "flex items-center gap-2 text-sm") do
      safe_join([
        content_tag(:span, label, class: "w-44 shrink-0 text-gray-600"),
        content_tag(:div, class: "h-4 flex-1 rounded bg-gray-100") do
          content_tag(:div, "", class: "h-4 rounded #{color}", style: "width: #{width}%")
        end,
        content_tag(:span, caption, class: "w-28 shrink-0 text-right tabular-nums text-gray-700")
      ])
    end
  end

  # Célula do mapa de calor: quanto mais frequente a dezena, mais escura.
  def heat_cell(entry, min, max)
    ratio = max == min ? 0.5 : (entry.count - min).to_f / (max - min)
    alpha = (0.12 + 0.88 * ratio).round(2)
    text = ratio > 0.55 ? "#ffffff" : "#064e3b"
    title = "Dezena #{two_digits(entry.number)}: #{entry.count} vez(es) — #{percent(entry.percent_of_draws)} dos concursos"

    content_tag(:div, title: title, class: "rounded p-2 text-center",
                      style: "background-color: rgba(5, 150, 105, #{alpha}); color: #{text}") do
      safe_join([
        content_tag(:div, two_digits(entry.number), class: "text-sm font-bold"),
        content_tag(:div, entry.count, class: "text-xs tabular-nums")
      ])
    end
  end

  # Gráfico de linhas em SVG puro (sem dependências de JavaScript).
  # points: objetos com #percent, #label e #to. Linha tracejada = esperado (10%).
  def evolution_chart(points, expected: 10.0, width: 720, height: 240)
    return if points.empty?

    left, right, top, bottom = 44, 14, 14, 34
    plot_w = width - left - right
    plot_h = height - top - bottom
    y_max = [ points.map(&:percent).max, expected ].max * 1.25
    y_max = y_max.ceil.to_f

    x_for = ->(i) { points.size == 1 ? left + plot_w / 2.0 : left + plot_w * i / (points.size - 1.0) }
    y_for = ->(value) { top + plot_h - (value / y_max * plot_h) }

    svg = +""
    [ 0, 0.25, 0.5, 0.75, 1 ].each do |step|
      value = y_max * step
      y = y_for.call(value).round(1)
      svg << %(<line x1="#{left}" y1="#{y}" x2="#{width - right}" y2="#{y}" stroke="#e5e7eb"/>)
      svg << %(<text x="#{left - 6}" y="#{y + 4}" text-anchor="end" font-size="11" fill="#6b7280">#{value.round}%</text>)
    end

    expected_y = y_for.call(expected).round(1)
    svg << %(<line x1="#{left}" y1="#{expected_y}" x2="#{width - right}" y2="#{expected_y}" stroke="#f59e0b" stroke-dasharray="5 4"/>)

    coords = points.each_with_index.map { |p, i| "#{x_for.call(i).round(1)},#{y_for.call(p.percent).round(1)}" }
    svg << %(<polyline points="#{coords.join(' ')}" fill="none" stroke="#059669" stroke-width="2"/>)

    label_every = (points.size / 10.0).ceil
    points.each_with_index do |point, i|
      x = x_for.call(i).round(1)
      y = y_for.call(point.percent).round(1)
      title = ERB::Util.h("Concursos #{point.label}: #{percent(point.percent)}")
      svg << %(<circle cx="#{x}" cy="#{y}" r="3.5" fill="#059669"><title>#{title}</title></circle>)
      next unless (i % label_every).zero?

      svg << %(<text x="#{x}" y="#{height - 12}" text-anchor="middle" font-size="11" fill="#6b7280">#{ERB::Util.h(point.to)}</text>)
    end

    tag.svg(svg.html_safe, viewBox: "0 0 #{width} #{height}", class: "w-full",
                           role: "img", "aria-label": "Evolução da frequência por bloco de concursos")
  end
end
