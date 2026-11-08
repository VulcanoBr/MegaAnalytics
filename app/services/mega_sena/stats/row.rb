module MegaSena
  module Stats
    Row = Struct.new(:contest_number, :draw_date, :numbers, keyword_init: true) do
      def sum = numbers.sum
      def evens = numbers.count(&:even?)
    end
  end
end