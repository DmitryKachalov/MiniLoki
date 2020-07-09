require_relative 'numbers'

module MiniLokiC
  module Formatize
    module Money # module for money
      module_function
      include Numbers

      def add_commas(value)
        value.positive? ? "$#{Numbers.add_commas(value)}" : "-$#{Numbers.add_commas(value.abs)}"
      end

      def huge_money_to_text(value)
        value.positive? ? "$#{Numbers.huge_number_to_text(value)}" : "-$#{Numbers.huge_number_to_text(value)}"
      end
    end
  end
end