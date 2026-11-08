require "test_helper"
require "support/draw_factory"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include DrawFactory

  test "sem concursos mostra estado vazio" do
    get dashboard_path
    assert_response :success
    assert_match(/Ainda não há concursos/, response.body)
  end

  test "com concursos renderiza o dashboard" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    create_draw(2, [ 7, 8, 9, 10, 11, 12 ])

    get root_path
    assert_response :success
    assert_match(/Dashboard estatístico/, response.body)
    assert_match(/<svg/, response.body)
  end

  test "aceita período, dezena e bloco" do
    10.times { |i| create_draw(i + 1, [ 1, 2, 3, 4, 5, 6 ].map { |n| n + i }) }

    get dashboard_path(window: "50", number: 7, block: 50)
    assert_response :success
    assert_match(/Comparativo/, response.body)
    assert_match(/dezena 07/, response.body)
  end

  test "parâmetros inválidos usam os padrões" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])

    get dashboard_path(window: "xyz", number: "999", block: "-1")
    assert_response :success
  end
end
