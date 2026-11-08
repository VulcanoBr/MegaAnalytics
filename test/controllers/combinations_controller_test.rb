require "test_helper"
require "support/draw_factory"

class CombinationsControllerTest < ActionDispatch::IntegrationTest
  include DrawFactory

  test "sem concursos mostra estado vazio" do
    get combinations_path
    assert_response :success
    assert_match(/Ainda não há concursos/, response.body)
  end

  test "renderiza pares, ternos e repetições" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ])

    get combinations_path
    assert_response :success
    assert_match(/Pares mais frequentes/, response.body)
    assert_match(/Ternos mais frequentes/, response.body)
    assert_match(/Repetição de dezenas/, response.body)
    assert_match(/01 – 02/, response.body)
  end

  test "aceita filtro por dezena, período e limite" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ])

    get combinations_path(number: 7, window: "50", limit: 10)
    assert_response :success
    assert_match(/dezena <strong>07/, response.body)
  end

  test "com um único concurso mostra aviso na repetição" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])

    get combinations_path
    assert_response :success
    assert_match(/ao menos dois concursos consecutivos/, response.body)
  end

  test "parâmetros inválidos usam os padrões" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])

    get combinations_path(window: "xyz", number: "999", limit: "-5")
    assert_response :success
  end
end
