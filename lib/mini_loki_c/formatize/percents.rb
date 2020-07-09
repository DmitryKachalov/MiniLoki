# frozen_string_literal: true

module MiniLokiC
  module Formatize
    module Percents # module for percents
      module_function

      def calculate_percent(curr, prev, sign = false)
        return '--' if [curr, prev].include?('Insufficient data')
        return '0' if curr.eql?('0')

        res = ((curr.to_f - prev) / prev) * 100
        res = sign ? res : res.abs
        format_percentage(res)
      end

      def format_percentage(value, symbol = false)
        value = "#{('%.1f' % value.to_f).to_s.sub(/\.0$/, '')}#{symbol ? '%' : ''}"
        value = '-' if value.match(/NaN/)
        value
      end
    end
  end
end