# frozen_string_literal: true

module MiniLokiC
  module Population
    module Frame
      class LokiCDate < Date
        def quarter
          case self.month
          when 1..3; 1
          when 4..6; 2
          when 7..9; 3
          else 4
          end
        end
        
        def half_year
          (1..6).include?(self.month) ? 1 : 2
        end
      end
      
      def self.[](period, date)
        date = LokiCDate.parse(date)
        
        case period
        when :daily;      "d:#{date.yday}:#{date.year}"
        when :weekly;     "w:#{date.cweek}:#{date.year}"
        when :monthly;    "m:#{date.month}:#{date.year}"
        when :quarterly;  "q:#{date.quarter}:#{date.year}"
        when :biannually; "b:#{date.half_year}:#{date.year}"
        else :annually;   "#{date.year}"
        end
      end
    end
  end
end
