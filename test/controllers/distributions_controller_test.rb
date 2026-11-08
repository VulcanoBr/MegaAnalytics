require "test_helper"
require "support/draw_factory"

class DistributionsControllerTest < ActionDispatch::IntegrationTest
  include DrawFactory

  test "sem concursos mostra estado vazio" do
    get distributions_path
    assert_response :success
    assert_match(/Ainda não há concursos/, response.body)
  end

  test "renderiza consecutivas e faixas" do
    create_draw(1, [ 1, 2, 3, 10, 20, 30 ])
    create_draw(2, [ 5, 16, 27, 38, 49, 60 ])

    get distributions_path
    assert_response :success
    assert_match(/Dezenas consecutivas no mesmo concurso/, response.body)
    assert_match(/Faixas numéricas/, response.body)
    assert_match(/Perfil de distribuição por faixas/, response.body)
    assert_match(/01–10/, response.body)
  end

  test "período e parâmetros inválidos" do
    create_draw(1, [ 1, 3, 5, 7, 9, 11 ])

    get distributions_path(window: "100")
    assert_response :success

    get distributions_path(window: "xyz")
    assert_response :success
    assert_match(/Nenhuma sequência no período/, response.body)
  end
end
