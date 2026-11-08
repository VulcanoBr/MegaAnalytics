require "test_helper"
require "support/draw_factory"

class FrequenciesControllerTest < ActionDispatch::IntegrationTest
  include DrawFactory

  setup do
    # ganhadores: 1→0, 2→1, 3→0, 4→2, 5→0
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ]).update!(winners_sena: 0)
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ]).update!(winners_sena: 1)
    create_draw(3, [ 1, 2, 3, 7, 8, 9 ]).update!(winners_sena: 0)
    create_draw(4, [ 10, 11, 12, 13, 14, 15 ]).update!(winners_sena: 2)
    create_draw(5, [ 10, 11, 12, 13, 14, 15 ]).update!(winners_sena: 0)
  end

  test "sem filtros mostra as 60 dezenas de todo o histórico" do
    get frequency_path
    assert_response :success
    assert_select "table tbody tr", 60
    assert_match(/Concursos encontrados/, response.body)
  end

  test "filtra por intervalo de concursos" do
    get frequency_path(contest_from: 2, contest_to: 4)
    assert_response :success
    assert_select "table tbody tr", 60
    assert_match(/Concursos 2 a 4/, response.body)
    assert_match(/#2 a #4/, response.body)
  end

  test "filtra por ganhadores da Sena e mostra a distância quando o conjunto não é contíguo" do
    get frequency_path(winners_min: 0, winners_max: 0)   # concursos 1, 3 e 5
    assert_response :success
    assert_match(/exatamente 0/, response.body)
    assert_match(/Distância/, response.body)
  end

  test "conjunto contíguo não mostra a coluna de distância" do
    get frequency_path(contest_from: 1, contest_to: 3)
    assert_response :success
    assert_no_match(/Distância/, response.body)
  end

  test "aceita ordenação" do
    %w[number count delay].each do |sort|
      get frequency_path(sort: sort)
      assert_response :success
    end

    get frequency_path(sort: "xyz")
    assert_response :success
  end

  test "intervalo inválido mostra aviso e nenhum concurso" do
    get frequency_path(contest_from: 10, contest_to: 2)
    assert_response :success
    assert_match(/concurso inicial/, response.body)
    assert_match(/Nenhum concurso encontrado/, response.body)
  end

  test "sem resultados para os filtros" do
    get frequency_path(winners_min: 50)
    assert_response :success
    assert_match(/Nenhum concurso encontrado/, response.body)
  end

  test "exporta CSV respeitando os filtros" do
    get frequency_path(format: :csv, winners_min: 0, winners_max: 0)

    assert_response :success
    assert_match %r{text/csv}, response.media_type
    assert_equal [ 0xEF, 0xBB, 0xBF ], response.body.bytes.first(3)
    assert_includes response.body, "Dezena;Vezes"
    assert_equal 61, response.body.lines.size
    assert_includes response.headers["Content-Disposition"], "megasena_frequencia_ganhadores-0-0.csv"
  end

  test "os mesmos filtros funcionam na lista de concursos e no relatório" do
    get draws_path(contest_from: 2, contest_to: 4, winners_min: 0, winners_max: 0)   # só o concurso 3
    assert_response :success
    assert_select "table tbody tr", 1

    get report_path(contest_from: 1, contest_to: 3)
    assert_response :success
    assert_match(/Concursos 1 a 3/, response.body)
  end
end
