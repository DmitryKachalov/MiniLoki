# frozen_string_literal: true

module MiniLokiC
  module Population
    module Formatize
      # module for money
      module Money
        module_function

        def add_commas(value)
          if value.positive?
            "$#{Formatize::Numbers.add_commas(value)}"
          else
            "-$#{Formatize::Numbers.add_commas(value.abs)}"
          end
        end

        def huge_money_to_text(value)
          if value.positive?
            "$#{Formatize::Numbers.huge_number_to_text(value)}"
          else
            "-$#{Formatize::Numbers.huge_number_to_text(value)}"
          end
        end
      end
    end
  end
end
