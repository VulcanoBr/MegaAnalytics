require "test_helper"
require "support/draw_factory"

class FrequenciesValuesControllerTest < ActionDispatch::IntegrationTest
  include DrawFactory

  setup do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ]).update!(winners_sena: 1, prize_sena: 45_000_000, estimated_prize: 50_000_000)
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ]).update!(winners_sena: 1, prize_sena: 55_000_000, estimated_prize: 60_000_000)
    create_draw(3, [ 10, 11, 12, 13, 14, 15 ]).update!(winners_sena: 2, prize_sena: 58_000_000, estimated_prize: 3_000_000)
    create_draw(4, [ 20, 21, 22, 23, 24, 25 ]).update!(winners_sena: 0, estimated_prize: 52_000_000)
  end

  test "filtra por intervalo de valor com números no formato brasileiro" do
    get frequency_path(value_min: "50.000.000,00", value_max: "60.000.000,00")

    assert_response :success
    assert_select "table tbody tr", 60
    assert_match(/Prêmio da Sena/, response.body)
    assert_match(/#2 a #3/, response.body)
  end

  test "escolhe o campo de valor" do
    get frequency_path(value_field: "estimated_prize", value_min: "50000000", value_max: "60000000")

    assert_response :success
    assert_match(/Estimativa de prêmio/, response.body)
    assert_match(/#1 a #4/, response.body)
    assert_match(/Distância/, response.body)   # concursos 1, 2 e 4: conjunto com buraco
  end

  test "valor sem resultados" do
    get frequency_path(value_min: "1.000.000.000,00")

    assert_response :success
    assert_match(/Nenhum concurso encontrado/, response.body)
  end

  test "mínimo maior que o máximo mostra aviso" do
    get frequency_path(value_min: "60.000.000", value_max: "50.000.000")

    assert_response :success
    assert_match(/valor mínimo/, response.body)
    assert_match(/Nenhum concurso encontrado/, response.body)
  end

  test "campo inválido é ignorado" do
    get frequency_path(value_field: "xyz", value_min: "50.000.000")
    assert_response :success
    assert_match(/Prêmio da Sena/, response.body)
  end

  test "exporta CSV com o filtro de valor" do
    get frequency_path(format: :csv, value_min: "50.000.000,00", value_max: "60.000.000,00")

    assert_response :success
    assert_includes response.body, "Dezena;Vezes"
    assert_includes response.headers["Content-Disposition"], "megasena_frequencia_valor-premio-sena-50000000-60000000.csv"
  end

  test "os atalhos de valor aparecem na página" do
    get frequency_path
    assert_response :success
    assert_match(/Atalhos de valor/, response.body)
    assert_match(/Acima de R\$ 100 mi/, response.body)
  end

  test "mantém o filtro de valor ao usar atalhos de outro grupo" do
    get frequency_path(value_min: "50.000.000", value_max: "60.000.000")
    assert_select "a[href*=?]", "value_min=50000000.00"
  end

  test "o mesmo filtro funciona na lista de concursos e no relatório" do
    get draws_path(value_min: "50.000.000", value_max: "60.000.000")
    assert_response :success
    assert_select "table tbody tr", 2    # concursos 2 e 3

    get report_path(value_min: "50.000.000", value_max: "60.000.000")
    assert_response :success
    assert_match(/Prêmio da Sena/, response.body)
  end
end
