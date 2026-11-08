module MegaSena
  module Stats
    
    # Carrega o histórico uma única vez (pluck) para que todos os cálculos
    # trabalhem em memória, sem consultas repetidas.
    class Dataset
      include Enumerable

      attr_reader :rows

      # scope: qualquer relation de Draw (ex.: filtrada por período). A ordem é sempre por concurso.
      def self.load(scope = Draw.all)
        columns = %i[contest_number draw_date] + Draw::NUMBER_COLUMNS
        rows = scope.reorder(:contest_number).pluck(*columns).map do |contest, date, *numbers|
          Row.new(contest_number: contest, draw_date: date, numbers: numbers)
        end
        new(rows)
      end

      def initialize(rows)
        @rows = rows
      end

      def each(&)
        rows.each(&)
      end

      def size = rows.size
      def empty? = rows.empty?
      def first_row = rows.first
      def last_row = rows.last

      # true quando os concursos são seguidos (sem buracos). Conjuntos filtrados
      # (ex.: por número de ganhadores) normalmente não são contíguos.
      def contiguous?
        rows.each_cons(2).all? { |a, b| b.contest_number == a.contest_number + 1 }
      end

      # Últimos n concursos; nil devolve o próprio conjunto completo.
      def window(limit)
        limit ? self.class.new(rows.last(limit)) : self
      end
    end
  end
end
