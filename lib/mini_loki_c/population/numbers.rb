#Module for money and numbers

module Numbers
  module_function

  def mysql_time(time)
    time.to_s.sub(/.*\b(\d{2}:\d{2}:\d{2}\b).*/, '\1')
  end

  def num_to_words(number)
    number = number.to_s.sub(/(\.\d{2}).*/, '\1').sub(/\.0{1,}/, '')
    return number.to_f if number.to_s.match(/\./)
    number = number.to_i
    return $single_digit[number] if number < 10
    return number
  end

  #converts int numbers to readable words
  def Numbers.in_words(int)
    numbers_to_name = {
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
    }
    str = ''
    numbers_to_name.each do |num, name|
      if int == 0
        return str
      elsif int.to_s.length == 1 && int/num > 0
        return str + "#{name}"
      elsif int < 100 && int/num > 0
        return str + "#{name}" if int%num == 0
        return str + "#{name} " + in_words(int%num)
      elsif int/num > 0
        return str + in_words(int/num) + " #{name} " + in_words(int%num)
      end
    end
  end

  def Numbers.word_to_num(word)
    return '' if !word
    case word.downcase
    when 'one'
      return 1
    when 'two'
      return 2
    when 'three'
      return 3
    when 'four'
      return 4
    when 'five'
      return 5
    when 'six'
      return 6
    when 'seven'
      return 7
    when 'eight'
      return 8
    when 'nine'
      return 9
    end
    return word
  end

  def Numbers.nthification(number, no_text = false)
    number = number.is_a?(String) ? number.to_i : number

    if number > 9
      postfix =
        if (11..13).include?(number % 100)
          'th'
        else
          case number % 10
          when 1; 'st'
          when 2; 'nd'
          when 3; 'rd'
          else    'th'
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

  def Numbers.monthday(date)
    input = monthday_year(date)
    output = input.sub(/,.*$/, '')
    return output
  end

  def Numbers.monthday_year(date)
    year, month, day = date.split('-')
    month = $numbers_to_months[month.to_i]
    output = "#{month} #{day.to_i}, #{year}"
    return output
  end

  def Numbers.percentage_string_to_float(string)
    return 0 if string == nil
    return string.to_f if !string.is_a?(String)
    string = string.gsub(/\%/, '').gsub(/[^0-9]/, '').gsub(/\s/, '').strip.chomp
    return string.to_f
  end

  #take a number -- "234233542" or "234345323.2343" -- and separate by commas, leaving decimal unchanged.
  def Numbers.numbers_add_commas(value)
    value = value.to_s
    return value if value[/[^[0-9]\.]/]
    #shield the decimals from comma introduction (store separate, add again at the end)
    decimal = ''
    decimal = value[/\.\d+\Z/]
    value = value.sub(/\.\d+\Z/, '')

    #add commas in correct places
    value.reverse!
    ary = value.scan(/\d{1,3}/)
    output = ary.join(',')
    value = output.reverse

    #reintroduce decimal
    value = value << decimal.to_s

    return value
  end

  def Numbers.phone_strip_format(input)
    input = Numbers::phone_strip(input)
    input = Numbers::phone_formatting(input)
    return input
  end

  def Numbers.phone_strip(input)
    input == nil ? '' : input.sub(/^[^\d]+/, '').sub(/^\s*(?:1-?\s?\+?)?(\(?\d{3}(?:\) ?| |\s*-\s*|\.|)\d{3}(?: |\s*-\s*|\.|\?)\d{4}\b).*/, '\1')
  end

  def Numbers.phone_formatting(input)
    input = '' if input == nil
    output = Array.new
    array = input.split(/,/)
    array.each do |input|
      input = input.sub(/^\s*\+1\s*/, '')
      input = input.gsub(/\.+\s*$/, '')
      input = input.gsub(/^\s*\.\s*/, '')
      input = input.sub(/^\s*none\s*$/i, '').sub(/^\s*no phone\s*$/i, '').sub(/^\s*N\/A\s*$/i, '').sub(/^\s*NULL\s*$/, '').sub(/\((\d+)\)\s*$/, ' EXT \1')
      input = input.sub(/^(phone:?|fax:?|office:?)\s*/i, '').sub(/(phone:?|fax:?|office:?)\s*$/i, '').sub(/^\s*\(\s*\)\s*$/, '').sub(/\(\s*$/, '')
      input = input.gsub(/^(\b1\b|\b011\b)?(?: +|-+|\.+|)?\(?(\d{3})(?:\)| +|\s*-+\s*|\) |\.+|\/|)(\d{3})(?:\.+|\s*-+\s*|\s*\?\s*|\s*)(\d{4})\s*(\b(?:ext|x)\.?\s*\d+)?\s*$/i, '\1-\2-\3-\4 \5').sub(/^\s*-\s*/, '').sub(/^800-/, '1-800-').sub(/\s*$/, '').sub(/^\s*/, '')
      input = input.gsub(/ (?:ext|x)\.?\s*(\d+)\s*$/i, ' ext. \1')
      output << input
    end
    input = ''
    output.each do |out|
      input = input + ', ' + out
    end
    input = input.sub(/^\s*,\s*/, '')
    input = input.sub(/\s,\s*$/, '')
    input = input.gsub(/\s{2,}/, ' ')
    return input
  end

  def Numbers.pl_phone_and_extension(input)
    input = Numbers.phone_formatting(input)
    input = input.gsub(/\A1\-/, '')
    phone, extension = input.split /\s+ext\.\s+/
    return phone, extension
  end

  def Numbers.overeaters_meetings(string)
    string = string.sub(/(.*) at (.*)/, '\2, \1').sub(/^0/, '')
    return string
  end

  #Format quantities of money *if* originally formatted in one of the following ways:
  #1. Any combination of only numbers, commas, and/or a decimal point (21323423423, 23423423324.000, 23423423.59684, 234,234.00, 234,234,234,234)
  #2. The above surrounded surrounded by other characters (sdf23434345234fjdka, ADS234,234,234.00KFDAE---)
  #3. The value prepended by a dollar sign ($234345345)
  def Numbers.money(input)
    #puts input
    if input == nil or input == '' or input.to_s[/^[\$]+$/]
      return ''
    end
    #convert to string:
    monetary_value = input.to_s

    #remove letters before or after value.
    monetary_value = monetary_value.sub(/\A(?:[^\d]{0,})(\d[\,\d]+(?:\.{0,1}\d{0,}))(?:\D{0,})/i, '\1')

    #remove commas
    monetary_value = monetary_value.gsub(/\,/, '')

    #dele decimals with only zeros
    monetary_value = monetary_value.sub(/\.0+\Z/, '')

    #Add commas
    monetary_value = Numbers.numbers_add_commas(monetary_value)

    #decimal formatting
    monetary_value = monetary_value.gsub(/\.(\d{2})\d+\Z/, '.\1').gsub(/\.(\d)\Z/, '.\10')

    #add dollar sign before input
    monetary_value.prepend('$')
    return monetary_value
  end

  #The following method takes a number (whether as a string or int) as an input and decides whether it should be written out. It should not be used for addresses, numbers at the beginning of a sentence, highways, dimensions, percentages, temperatures, speeds, dates or times. It ignores context and will get cases like these wrong. It is best applied to counting numbers -- the "2" in "2 students", "2 houses", etc.
  def Numbers.simple_ap_number_converter(input)
    if /^\d$/.match(input.to_s)
      output = input.to_s.sub(/1/, 'one').sub(/2/, 'two').sub(/3/, 'three').sub(/4/, 'four').sub(/5/, 'five').sub(/6/, 'six').sub(/7/, 'seven').sub(/8/, 'eight').sub(/9/, 'nine')
    else
      output = input.to_s
    end
    puts output
  end

  def Numbers.to_ap_style(input)
    if /^\d$/.match(input.to_s)
      output = input.to_s.sub(/1/, 'one').sub(/2/, 'two').sub(/3/, 'three').sub(/4/, 'four').sub(/5/, 'five').sub(/6/, 'six').sub(/7/, 'seven').sub(/8/, 'eight').sub(/9/, 'nine')
    else
      output = input.to_s
    end
    puts output
    return output
  end

  def Numbers.format_decimal_pct_to_string(pct)
    pct_string = ''

    zeros = ''
    number = 0
    number_str = ''
    if pct.to_s =~ /^0\.(0+)([1-9])/i
      zeros = $1
      number = $2
    elsif pct.to_s =~ /^0\.([1-9])/i
      zeros = ''
      number = $1
    elsif pct.to_s =~ /^(\d+)\.0+$/i
      return Numbers.digit_to_string($1)
    elsif pct.to_s =~ /^(\d+)$/i
      return Numbers.digit_to_string($1)
    else
      return sprintf '%14.2f', pct
    end

    zeros = zeros.to_s.count '0'
    #puts zeros

    number_str = Numbers.digit_to_string(number)

    pct_string = "#{number_str}"

    if zeros.to_i == 0
      pct_string += ' tenths'
    elsif zeros.to_i == 1
      pct_string += ' hundredths'
    elsif zeros.to_i == 2
      pct_string += ' thousandths'
    elsif zeros.to_i == 3
      pct_string += ' ten-thousandths'
    elsif zeros.to_i == 4
      pct_string += ' hundred-thousandths'
    elsif zeros.to_i == 5
      pct_string += ' millionths'
    elsif zeros.to_i == 6
      pct_string = "0.#{number} millionths"
    elsif zeros.to_i == 7
      pct_string = "0.0#{number} millionths"
    elsif zeros.to_i == 8
      pct_string += ' billionths'
    elsif zeros.to_i == 9
      pct_string = "0.#{number} billionths"
    elsif zeros.to_i == 10
      pct_string = "0.0#{number} billionths"
    elsif zeros.to_i == 11
      pct_string += ' trillionths'
    elsif zeros.to_i == 12
      pct_string = "0.#{number} trillionths"
    elsif zeros.to_i == 13
      pct_string = "0.0#{number} trillionths"
    end

    pct_string = pct_string.gsub(/s$/i, '') if number.to_i == 1

    return pct_string
  end

  def Numbers.digit_to_string(number)
    number_str = 'one' if number.to_i == 1
    number_str = 'two' if number.to_i == 2
    number_str = 'three' if number.to_i == 3
    number_str = 'four' if number.to_i == 4
    number_str = 'five' if number.to_i == 5
    number_str = 'six' if number.to_i == 6
    number_str = 'seven' if number.to_i == 7
    number_str = 'eight' if number.to_i == 8
    number_str = 'nine' if number.to_i == 9
    number_str = number if number.to_i > 9

    return number_str
  end

end