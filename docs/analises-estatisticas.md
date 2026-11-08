## [← Voltar ao README](../README.md)

---

# Análises estatísticas

Este documento define cada análise do MegaStats e mostra **como o valor esperado por acaso é calculado**. Em cada concurso são sorteadas 6 dezenas entre 60, todas as combinações são igualmente prováveis (há `C(60, 6) = 50.063.860` possíveis) e os sorteios são independentes.

> As análises são **descritivas**. Elas comparam o histórico com o que o acaso produziria; não preveem resultados futuros.

## Como ler as comparações

Quase todas as telas mostram o valor **observado** ao lado do **esperado por acaso**. Diferenças pequenas são normais: com poucos concursos (ou com combinações raras, como ternos), a flutuação aleatória é grande. Uma dezena ou combinação no topo de um ranking não indica tendência; em qualquer ranking, alguém precisa ficar em primeiro.

Notação: `C(n, k)` é o coeficiente binomial ("n escolhe k").

## Períodos (janelas)

O dashboard, as combinações e as distribuições analisam um recorte do histórico:

| Janela           | Conjunto analisado            |
| ---------------- | ----------------------------- |
| Últimos 50       | Os 50 concursos mais recentes |
| Últimos 100      | Os 100 mais recentes          |
| Últimos 500      | Os 500 mais recentes          |
| Todo o histórico | Todos os concursos            |

O **relatório** (`/report`) usa um período por datas, com início e fim livres.

## 1. Frequência das dezenas

Para cada dezena de 01 a 60, no conjunto analisado:

| Indicador           | Definição                                                        | Esperado por acaso |
| ------------------- | ---------------------------------------------------------------- | ------------------ |
| Frequência absoluta | Quantidade de concursos em que a dezena saiu                     | —                  |
| % dos concursos     | Frequência ÷ total de concursos                                  | `6 / 60 = 10%`     |
| % das dezenas       | Frequência ÷ (total de concursos × 6)                            | `1 / 60 ≈ 1,67%`   |
| Último concurso     | Número do concurso da última aparição                            | —                  |
| Sem sair há         | Concursos decorridos desde a última aparição, dentro do conjunto | —                  |
| Intervalo médio     | (último − primeiro concurso em que apareceu) ÷ (aparições − 1)   | ≈ 10 concursos     |

Rankings: as 10 dezenas mais sorteadas, as 10 menos sorteadas e as 10 com maior tempo sem sair.

**Comparativo entre períodos:** para uma janela (50/100/500), mostra a diferença em pontos percentuais entre a frequência da janela e a de todo o histórico, destacando as dezenas mais "acima" e mais "abaixo" da média histórica.

**Evolução histórica:** para uma dezena escolhida, a % dos concursos que a continham em cada bloco de 50, 100, 200 ou 500 concursos. A linha tracejada marca os 10% esperados. O último bloco pode ser parcial.

## 2. Pares e ímpares

Quantos concursos tiveram 0, 1, …, 6 dezenas pares (e, portanto, 6, 5, …, 0 ímpares).

## 3. Soma das dezenas

Soma das seis dezenas de cada concurso (mínima possível 21, máxima 345), agrupada em faixas de 20. Exibe mínimo, máximo, média e mediana.

## 4. Pares e ternos mais frequentes

Para cada par (ou terno) de dezenas, conta em quantos concursos as dezenas saíram **juntas**.

| Indicador       | Definição                                      |
| --------------- | ---------------------------------------------- |
| Vezes           | Concursos em que a combinação apareceu inteira |
| % dos concursos | Vezes ÷ total de concursos                     |
| × esperado      | Vezes observadas ÷ vezes esperadas por acaso   |
| Último          | Concurso da última aparição                    |

Probabilidade de uma combinação **específica** estar entre as 6 dezenas sorteadas:

```text
P(par)   = C(6,2) / C(60,2) = 15 / 1.770   ≈ 0,847%
P(terno) = C(6,3) / C(60,3) = 20 / 34.220  ≈ 0,058%
```

Também exibe quantos dos 1.770 pares e dos 34.220 ternos possíveis já saíram juntos, e permite filtrar apenas combinações que contêm determinada dezena (nesse caso o total possível passa a `C(59, k−1)`).

## 5. Repetição entre concursos consecutivos

Quantas das 6 dezenas de um concurso já tinham saído no concurso **imediatamente anterior**. Pares de concursos não consecutivos (por lacuna) são ignorados.

Se os sorteios são independentes, o número `k` de dezenas repetidas segue uma distribuição hipergeométrica:

```text
P(k) = C(6, k) × C(54, 6 − k) / C(60, 6)
```

| Repetidas |       0 |       1 |      2 |      3 |
| --------- | ------: | ------: | -----: | -----: |
| Esperado  | ≈ 51,6% | ≈ 37,9% | ≈ 9,5% | ≈ 1,0% |

Média esperada de dezenas repetidas: `6 × 6 / 60 = 0,6`.

Além da distribuição, a tela mostra, por dezena, a **taxa de repetição** (vezes em que saiu em dois concursos seguidos ÷ vezes em que saiu e havia um concurso seguinte; esperado ≈ 10%) e as repetições mais recentes.

## 6. Dezenas consecutivas no mesmo concurso

Um **par consecutivo** são duas dezenas `n` e `n+1` sorteadas juntas (ex.: 12 e 13). Uma sequência de 3 dezenas (40-41-42) conta como 2 pares; de 6 dezenas, como 5.

Um concurso com `k` pares consecutivos tem `b = 6 − k` blocos de dezenas seguidas. Contando as formas de dividir 6 dezenas em `b` blocos e posicioná-los entre 60 números:

```text
P(k) = C(5, 5 − k) × C(55, 6 − k) / C(60, 6)
```

| Pares consecutivos |       0 |       1 |      2 |      3 |
| ------------------ | ------: | ------: | -----: | -----: |
| Esperado           | ≈ 57,9% | ≈ 34,7% | ≈ 6,8% | ≈ 0,5% |

- Média esperada de pares consecutivos: **0,5** (59 pares possíveis × 1/118 cada).
- Concursos com **alguma** sequência: ≈ **42,1%** esperado.

A tela também mostra a maior sequência já sorteada, os pares `n–(n+1)` mais frequentes (um par específico aparece em ≈ 0,85% dos concursos) e as sequências mais recentes.

## 7. Faixas numéricas

As 60 dezenas são divididas em 6 faixas de 10: `01–10`, `11–20`, `21–30`, `31–40`, `41–50`, `51–60`.

| Indicador                     | Definição                            | Esperado por acaso          |
| ----------------------------- | ------------------------------------ | --------------------------- |
| Dezenas sorteadas             | Total de dezenas que caíram na faixa | —                           |
| % de todas as dezenas         | Dezenas da faixa ÷ (concursos × 6)   | `1/6 ≈ 16,67%`              |
| Média por concurso            | Dezenas da faixa ÷ concursos         | `1,0`                       |
| Concursos sem dezena na faixa | Concursos em que a faixa ficou vazia | `C(50,6) / C(60,6) ≈ 31,7%` |

**Perfil de distribuição por faixas:** número de dezenas em cada faixa, em ordem decrescente, omitindo faixas vazias. Exemplos: `2-2-1-1` (duas faixas com 2 dezenas e duas com 1; duas faixas vazias), `1-1-1-1-1-1` (uma dezena em cada faixa). Existem 11 perfis possíveis. A probabilidade de cada um é a soma, sobre todas as 462 formas de distribuir 6 dezenas em 6 faixas que resultam no mesmo perfil, de:

```text
Π C(10, cᵢ) / C(60, 6)
```

onde `cᵢ` é a quantidade de dezenas na faixa `i`. Os perfis mais prováveis são `2-2-1-1` (≈ 36,4%), `2-1-1-1-1` (≈ 27,0%) e `3-1-1-1` (≈ 14,4%).

## 8. Resumo financeiro (relatório)

Calculado no banco para os concursos do período:

| Indicador                       | Definição                                                       |
| ------------------------------- | --------------------------------------------------------------- |
| Arrecadação total               | Soma de `total_revenue`                                         |
| Média por concurso              | Arrecadação total ÷ concursos                                   |
| Prêmios da Sena pagos           | Soma de `winners_sena × prize_sena`                             |
| Concursos com ganhador da Sena  | Concursos com `winners_sena > 0` (e quantos ficaram acumulados) |
| Maior prêmio individual da Sena | Maior `prize_sena` e o concurso correspondente                  |
| Maior acumulado da Sena         | Maior `accumulated_sena` e o concurso correspondente            |

## Valores de referência

| Grandeza                                       | Valor esperado por acaso |
| ---------------------------------------------- | ------------------------ |
| Uma dezena em um concurso                      | 10%                      |
| Um par específico em um concurso               | ≈ 0,847%                 |
| Um terno específico em um concurso             | ≈ 0,058%                 |
| Dezenas repetidas do concurso anterior (média) | 0,6                      |
| Pares consecutivos por concurso (média)        | 0,5                      |
| Concursos com alguma dezena consecutiva        | ≈ 42,1%                  |
| Dezenas por faixa de 10, por concurso (média)  | 1,0                      |
| Concurso sem dezena em uma faixa de 10         | ≈ 31,7%                  |

Esses valores são calculados em `MegaSena::Stats::Combinatorics` com aritmética inteira exata e estão cobertos por testes.

---

## [← Voltar ao README](../README.md)

---
