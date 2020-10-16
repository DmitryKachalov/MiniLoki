# frozen_string_literal: true

module MiniLokiC
  module Population
    module Frame
      class LokiCDate < Date
        def quarter
          case month
          when 1..3 then 1
          when 4..6 then 2
          when 7..9 then 3
          else 4
          end
        end

        def half_year
          (1..6).include?(month) ? 1 : 2
        end
      end

      def self.[](period, date)
        date = LokiCDate.parse(date)

        case period
        when :daily then      "d:#{date.yday}:#{date.year}"
        when :weekly then     "w:#{date.cweek}:#{date.year}"
        when :monthly then    "m:#{date.month}:#{date.year}"
        when :quarterly then  "q:#{date.quarter}:#{date.year}"
        when :biannually then "b:#{date.half_year}:#{date.year}"
        when :annually then   date.year.to_s
        else raise ArgumentError, 'The passed frame is not correct.'
        end
      end
    end
  end
end
