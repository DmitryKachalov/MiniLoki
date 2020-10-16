# frozen_string_literal: true

module MiniLokiC
  module Formatize
    # module for numbers
    module Numbers
      module_function

      NUMBERS_TO_NAME = {
        1_000_000 => 'million',
        1000 => 'thousand',
        100 => 'hundred',
        90 => 'ninety',
        80 => 'eighty',
        70 => 'seventy',
        60 => 'sixty',
        50 => 'fifty',
        40 => 'forty',
        30 => 'thirty',
        20 => 'twenty',
        19 => 'nineteen',
        18 => 'eighteen',
        17 => 'seventeen',
        16 => 'sixteen',
        15 => 'fifteen',
        14 => 'fourteen',
        13 => 'thirteen',
        12 => 'twelve',
        11 => 'eleven',
        10 => 'ten',
        9 => 'nine',
        8 => 'eight',
        7 => 'seven',
        6 => 'six',
        5 => 'five',
        4 => 'four',
        3 => 'three',
        2 => 'two',
        1 => 'one'
      }.freeze

      def add_commas(value)
        parts = value.to_s.split('.')
        parts.first.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1,')
        parts.join('.')
      end

      # converts int numbers to readable words
      def in_words(value)
        value = value.to_i
        NUMBERS_TO_NAME.each_with_object('') do |(num, name), str|
          break if value.zero?
          return "#{str}#{name}" if value.to_s.length.eql?(1) && (value / num).positive?

          if value < 100 && (value / num).positive?
            return (value % num).zero? ? "#{str}#{name}" : "#{str}#{name} #{in_words(value % num)}"
          elsif (value / num).positive?
            return "#{str}#{in_words(value / num)} #{name} #{in_words(value % num)}".strip
          end
        end
      end

      def huge_number_to_text(value)
        billion = value / 1_000_000_000.0
        million = value / 1_000_000.0
        if billion.abs >= 1
          "#{add_commas(billion.to_f.round(1)).sub(/\.0$/, '')} billion"
        elsif million.abs >= 1
          "#{million.to_f.round(1).to_s.sub(/\.0$/, '')} million"
        else
          add_commas(value)
        end
      end

      def to_text(value)
        return if value < 0

        if value < 10
          %w[one two three four five six seven eight nine][value.to_i - 1]
        elsif value.abs > 999
          add_commas(value)
        else
          value
        end
      end

      def nthification(number, no_text = false)
        number = number.is_a?(String) ? number.to_i : number

        if number > 9
          postfix =
            if (11..13).include?(number % 100)
              'th'
            else
              case number % 10
              when 1 then 'st'
              when 2 then 'nd'
              when 3 then 'rd'
              else 'th'
              end
            end
          "#{number}#{postfix}"
        else
          ranks =
            if no_text
              %w[1st 2nd 3rd 4th 5th 6th 7th 8th 9th]
            else
              %w[first second third fourth fifth sixth seventh eighth ninth]
            end

          ranks[number - 1]
        end
      end
    end
  end
end
