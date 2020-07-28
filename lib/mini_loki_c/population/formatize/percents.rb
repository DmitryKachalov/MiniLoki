# frozen_string_literal: true

module MiniLokiC
  module Population
    module Formatize
      # module for percents
      module Percents
        module_function

        def calculate_percent(curr, prev, sign = false)
          return 0 if curr.to_i.eql?(0)

          res = ((curr.to_f - prev) / prev) * 100
          res = sign ? res : res.abs
          format_percentage(res)
        end

        def format_percentage(value, symbol = false)
          "#{'%.1f'.format(value.to_f).to_s.sub(/\.0$/, '')}#{symbol ? '%' : ''}"
        end
      end
    end
  end
end
