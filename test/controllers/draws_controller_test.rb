require "test_helper"
require "support/draw_factory"

class DrawsControllerTest < ActionDispatch::IntegrationTest
  include DrawFactory

  setup do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ], date: Date.new(2020, 1, 2))
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ], date: Date.new(2020, 1, 3)).update!(
      winners_sena: 1, prize_sena: 1500000, winners_quina: 10, prize_quina: 40000, city_uf: "RIO DE JANEIRO / RJ"
    )
    create_draw(3, [ 10, 11, 12, 13, 14, 15 ], date: Date.new(2020, 2, 10))
  end

  test "lista concursos" do
    get draws_path
    assert_response :success
    assert_select "table tbody tr", 3
  end

  test "filtra por dezena" do
    get draws_path(number: 10)
    assert_response :success
    assert_select "table tbody tr", 1
  end

  test "filtra por período" do
    get draws_path(from: "2020-01-03", to: "2020-01-31")
    assert_response :success
    assert_select "table tbody tr", 1
  end

  test "período invertido mostra aviso" do
    get draws_path(from: "2020-03-01", to: "2020-01-01")
    assert_response :success
    assert_match(/data inicial/, response.body)
  end

  test "pagina os resultados" do
    (4..30).each { |n| create_draw(n, [ 1, 2, 3, 4, 5, 6 ]) }

    get draws_path
    assert_select "table tbody tr", 25
    assert_match(/Página 1 de 2/, response.body)

    get draws_path(page: 2)
    assert_select "table tbody tr", 5
    assert_match(/Página 2 de 2/, response.body)

    get draws_path(page: 99)  # além do fim: usa a última página
    assert_match(/Página 2 de 2/, response.body)
  end

  test "ir para o concurso redireciona" do
    get draws_path(contest: 2)
    assert_redirected_to draw_path(Draw.find_by!(contest_number: 2))
    assert_equal "/draws/2", draw_path(Draw.find_by!(contest_number: 2))
  end

  test "concurso inexistente na busca" do
    get draws_path(contest: 999)
    assert_response :success
    assert_match(/999 não encontrado/, response.body)
  end

  test "exporta CSV respeitando os filtros" do
    get draws_path(format: :csv, from: "2020-01-03", to: "2020-01-31")

    assert_response :success
    assert_match %r{text/csv}, response.media_type
    assert_equal [ 0xEF, 0xBB, 0xBF ], response.body.bytes.first(3)
    assert_includes response.body, "Concurso;Data;Dezena 1"
    assert_includes response.headers["Content-Disposition"], "megasena_concursos_de-2020-01-03_ate-2020-01-31.csv"
    assert_equal 2, response.body.lines.size   # cabeçalho + 1 concurso
  end

  test "mostra o detalhe do concurso" do
    get draw_path(Draw.find_by!(contest_number: 2))

    assert_response :success
    assert_match(/Concurso 2/, response.body)
    assert_match(/Repetidas do anterior/, response.body)
    assert_match(/01 02 03/, response.body)
    assert_match(/RIO DE JANEIRO/, response.body)
    assert_select "a[href=?]", "/draws/1"
    assert_select "a[href=?]", "/draws/3"
  end

  test "primeiro concurso não tem anterior" do
    get draw_path(Draw.find_by!(contest_number: 1))

    assert_response :success
    assert_select "a[href=?]", "/draws/0", false
  end

  test "concurso inexistente redireciona para a lista" do
    get draw_path(9999)
    assert_redirected_to draws_path
  end
end
