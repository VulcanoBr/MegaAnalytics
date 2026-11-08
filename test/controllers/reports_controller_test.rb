require "test_helper"
require "support/draw_factory"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  include DrawFactory

  test "sem concursos mostra mensagem de período vazio" do
    get report_path
    assert_response :success
    assert_match(/Nenhum concurso encontrado/, response.body)
  end

  test "renderiza o relatório completo" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ], date: Date.new(2020, 1, 2)).update!(total_revenue: 1000, winners_sena: 0)
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ], date: Date.new(2020, 1, 3)).update!(total_revenue: 2000, winners_sena: 1, prize_sena: 900)

    get report_path
    assert_response :success
    assert_match(/Relatório estatístico/, response.body)
    assert_match(/Frequência das dezenas/, response.body)
    assert_match(/Arrecadação total/, response.body)
    assert_match(/Pares mais frequentes/, response.body)
    assert_match(/Últimos 12 meses/, response.body)
  end

  test "filtra por período" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ], date: Date.new(2020, 1, 2))
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ], date: Date.new(2020, 1, 3))

    get report_path(from: "2020-01-03", to: "2020-01-31")
    assert_response :success
    assert_match(/Concursos no período/, response.body)
    assert_no_match(/Nenhum concurso encontrado/, response.body)

    get report_path(from: "2021-01-01")
    assert_match(/Nenhum concurso encontrado/, response.body)
  end

  test "período invertido mostra aviso" do
    get report_path(from: "2020-03-01", to: "2020-01-01")
    assert_response :success
    assert_match(/data inicial/, response.body)
  end

  test "exporta CSV de frequência, pares e ternos" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])

    get report_path(format: :csv, section: "frequency")
    assert_response :success
    assert_match %r{text/csv}, response.media_type
    assert_includes response.body, "Dezena;Vezes"

    get report_path(format: :csv, section: "pairs")
    assert_includes response.body, "Combina"
    assert_includes response.headers["Content-Disposition"], "megasena_pairs"

    get report_path(format: :csv, section: "triples")
    assert_includes response.body, "Dezena 3"
  end

  test "seção de exportação inválida redireciona" do
    get report_path(format: :csv, section: "xyz")
    assert_redirected_to report_path
  end
end
