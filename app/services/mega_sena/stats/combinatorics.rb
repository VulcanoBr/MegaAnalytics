module MegaSena
  module Stats
    # Matemática combinatória usada pelas análises (sem estado).
    module Combinatorics
      module_function

      # Coeficiente binomial C(n, k) em inteiros exatos.
      def binom(n, k)
        return 0 if k.negative? || k > n

        (0...k).reduce(1) { |acc, i| acc * (n - i) / (i + 1) }
      end

      # Probabilidade de um conjunto específico de `size` dezenas estar entre as 6 sorteadas.
      # Pares: 15/1770 ≈ 0,847%. Ternos: 20/34220 ≈ 0,058%.
      def probability_of_set(size)
        binom(6, size).to_f / binom(60, size)
      end

      # Hipergeométrica: probabilidade de exatamente k das 6 dezenas de um concurso
      # estarem entre as 6 do concurso anterior (sorteios independentes).
      def probability_of_repeats(k)
        binom(6, k) * binom(54, 6 - k).to_f / binom(60, 6)
      end

      # Probabilidade de um concurso ter exatamente k pares de dezenas consecutivas (n, n+1).
      # Um concurso com k pares adjacentes tem b = 6 - k "blocos" de dezenas seguidas:
      # C(5, b-1) formas de dividir 6 dezenas em b blocos × C(55, b) formas de posicioná-los em 1..60.
      def probability_of_adjacent_pairs(k)
        return 0.0 unless (0..5).cover?(k)

        binom(5, 5 - k) * binom(55, 6 - k).to_f / binom(60, 6)
      end

      # Probabilidade de nenhuma das 6 dezenas cair em uma faixa de `band_size` dezenas.
      def probability_of_empty_band(band_size)
        binom(60 - band_size, 6).to_f / binom(60, 6)
      end

      # Probabilidade de cada "perfil de faixas" (dezenas por faixa em ordem decrescente,
      # faixas vazias omitidas). Ex.: [2, 1, 1, 1, 1] = 2 dezenas em uma faixa e 1 em cada outra de quatro.
      def band_profile_probabilities(band_size: 10)
        bands = 60 / band_size
        total = binom(60, 6)
        weights = Hash.new(0)

        compositions(6, bands).each do |counts|
          weight = counts.reduce(1) { |acc, count| acc * binom(band_size, count) }
          next if weight.zero?

          weights[counts.sort.reverse.reject(&:zero?)] += weight
        end

        weights.transform_values { |weight| weight.to_f / total }
      end

      # Todas as formas de distribuir `total` dezenas em `parts` faixas (ordem importa).
      def compositions(total, parts)
        return [ [ total ] ] if parts == 1

        (0..total).flat_map do |first|
          compositions(total - first, parts - 1).map { |rest| [ first ] + rest }
        end
      end
    end
  end
end
