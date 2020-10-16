# frozen_string_literal: true

module MiniLokiC
  module Formatize
    module Address
      module_function

      include Constants

      STREET_TYPES_REGEX = BuildRegex.new(STREET_TYPES).regex
      STATES_TO_AP_REGEX = BuildRegex.new(STATES_TO_AP).regex

      SAINT_REGEX = Regexp.new(('\bst\b\.*\s+(' + SAINTS + ')'), Regexp::IGNORECASE)

      def abbreviated_streets(street)
        street = '' if street.nil?
        street = street.sub(/\|?\s*\bfl\b\.?\s+(\d)/i, ', Floor \1')
        street = street.sub(/^\s*NULL\s*$/, '')
        street = street.gsub(/(?<! )\(/, ' (')
        street = street.gsub(/([NESW])\.FM/, '\1. FM')
        street = street.gsub(/\bapt\b\.(\b[A-Za-z0-9]{1,2}\b)/i, 'Apt. \1')
        street = street.sub(/([\,][\.\,]*)\s*$/, '')
        street = street.sub(/^\s*[\,\.\-\s]+\s*/, '')
        street = street.gsub(/(?<!\b1|\bc)\//i, ' and ')
        street = street.gsub(/\bwb\b/i, 'westbound')
        street = street.gsub(/\beb\b/i, 'eastbound')
        street = street.gsub(/\bnb\b/i, 'northbound')
        street = street.gsub(/\bsb\b/i, 'southbound')

        # Replaces html entities
        abb_street = html_entities(street)

        # P.O. Boxes handled
        # abb_street = abb_street.gsub( /((?:P\.?\s*O\.?)?\s+Box\s+[0-9A-Za-z]+)\,\s+(.+)/i, '\2, \1' ).gsub( /(?:P\.?\s*O\.?\s?)?\sbox\s+([0-9A-Za-z]+)/i, 'P.O. Box \1' )
        abb_street = abb_street.gsub(/\bP\.?\s*O\b\.? box\b/i, 'P.O. Box')
        abb_street = abb_street.gsub(/\bP\.?\s*O\b\.? drawer\b/i, 'P.O. Drawer')
        # U.S.
        abb_street = abbreviate_US(abb_street)

        # ordinals
        abb_street = ordinals(abb_street)

        # St. to Saint
        abb_street = to_saint(abb_street)

        # Abbreviates Ave., St., and Blvd. according to AP guidelines.
        abb_street = street_types(abb_street)
        abb_street = abb_street.gsub(/(\d+\b.+\b)(\bave?nue\b|\bavn?\b\.*|\bave\b\.*)/i, '\1Ave.').gsub(/(\d+\b.+\b)(\bBo?u?le?va?r?d\b\.*|\bBoulv?\b\.*)/i, '\1Blvd.').gsub(/(\d+\b.+\b)\bst(reet)?\b\.*/i, '\1St.')
        abb_street = abb_street.gsub(/\bst\b(?!\.)/i, 'Street')
        abb_street = abb_street.gsub(/\bave\b(?!\.)/i, 'Avenue')

        # Spells out all remaining street names according to AP guidelines.
        abb_street = normalize(abb_street)

        abb_street = abb_street.gsub(/\ba\b/, 'A')

        # Eliminates hashes in addresses.
        abb_street = abb_street.gsub(/(^\s*#*\s*)(?=\d+)/, '').gsub(/##/, 'No.').gsub(/(\bUnit\b|\bs(?:ui)?te\b|\bap(?:artmen)?t\b)\.?(?:\,)?\s*(?:#|No\.)?\s*(\b\d+\b)/i, '\1 \2').gsub(/#unit/, 'Unit').gsub(/#\s*(\d+\w{0,1})\s*(?:&|and)\s*(\d+\w{0,1})/i, 'Units \1 and \2').gsub(/#\s*(\d+)\b/, 'No. \1').gsub(/(?<=.|\s)(?:#|No\.)\s*(\b\d+\b)/i, 'No. \1').gsub(/(?:#|No\.)\s*(\d+\-?[a-zA-Z]|[a-zA-Z]\-?\d+)/i, 'Unit \1').gsub(/(?:#|No\.)\s*([A-Za-z])\s*(\d+\-?[a-zA-Z]?)/i, 'Unit \1\2')

        STREET_TYPES.each do |_key, value|
          abb_street = abb_street.gsub(/(#{value}) #\s*([A-Za-z]+)/, '\1, No. \2')
        end

        abb_street = abb_street.gsub(/ #\s*([A-Za-z])\b/, ', No. \1')

        # Add comma before 'Unit', 'No.', or 'Lot'
        abb_street = abb_street.gsub(/,?\s*\b(Unit\b|No\b\.|Lot\b)/i, ', \1')
        abb_street = abb_street.gsub(/(\bUnit\b|\bs(?:ui)?te\b|\bap(?:artmen)?t\b)\.?, No. ([A-Za-z])\b/i, '\1 \2')

        # Eliminates unnecessary information from before an address.
        abb_street = delete_pre_address(abb_street)

        # Suites and apartments
        # abb_street = abb_street.gsub( /(?<=\,)\s*\bs(ui)?te\.*/i, ' Suite' ).gsub( /(?<!\,)\s\bs(ui)?te\.*/i, ', Suite' ).gsub( /(?<!\,)\bs(ui)?te\.*/i, ', Suite' ).gsub( /(?<=\,)\s*\bap(artmen)?t\.*/i, ' Apt.' ).gsub( /(?<!\,)\s\bap(artmen)?t\.*/i, ', Apt.' ).gsub( /(?<!\,)\bap(artmen)?t\.*/i, ', Apt.' ).gsub( /\bSuite\s*([A-Za-z0-9\-]{1,5})\s(?:&|and)\s([A-Za-z0-9\-]{1,5})/i, 'Suites \1 and \2' )
        abb_street = abb_street.gsub(/,?\s*\bs(ui)?te\b\.?/i, ', Suite').gsub(/,?\s*\bap(artmen)?t\b\.?/i, ', Apt.').gsub(/\bSuite\s*([A-Za-z0-9\-]{1,5})\s(?:&|and)\s([A-Za-z0-9\-]{1,5})/i, 'Suites \1 and \2')

        # Abbreviating compass points
        abb_street = compass_pt_abbr(abb_street)

        # remove periods from suites, units, etc where they've been mistaken for cardinal directions
        abb_street = abb_street.gsub(/(\bUnit\b|\bs(?:ui)?te\b|\bap(?:artmen)?t\b)\.? ([NESWnesw])\./i, '\1 \2')

        # Exits
        abb_street = abb_street.gsub(/\(?Exit\s(\d+)\)?/i, 'at exit \1')

        # Finishing touches (Or: things that need to be done near the end of the street abbreviation process)
        abb_street = abb_street.gsub(/P\.o\./, 'P.O.')	#capitalizes 'o' in 'P.o.'
        if abb_street =~ /\b\d+\-?[a-z]\b/	#capitalizes, e.g., 'c' in '7c'
          unit = abb_street[/\b\d+\-?[a-z]\b/].upcase
          abb_street = abb_street.gsub(/\b\d+\-?[a-z]\b/, unit)
        end
        abb_street = abb_street.gsub(/\bUs\b/, 'US')	#Us to US
        abb_street = abb_street.gsub(/\bS\.e\./, 'S.E.').gsub(/\bS\.w\./, 'S.W.').gsub(/\bN\.e\./, 'N.E.').gsub(/\bN\.w\./, 'N.W.')

        # 'Saint' to 'St.'
        abb_street = from_saint(abb_street)

        STATES_TO_AP.each do |key, _value|
          abb_street = abb_street.gsub(/,?\s*(#{key})\s*$/i, ', \1')
        end

        STATES_TO_AP.each do |key, value|
          abb_street = abb_street.gsub(/#{key}(?! #{STREET_TYPES_REGEX})(?!,? #{STATES_TO_AP_REGEX})/i, value)
        end

        abb_street.gsub(/\.\./, '.')
      end

      def html_entities(line)
        return '' if line == '' || line.nil?

        line.gsub(/&amp;?|&\#38;/, '&').gsub(/&nbsp;|&\#160;/, ' ').gsub(/&lt;|&\#60;/, '<').gsub(/&gt;|&#62;/, '>').gsub(/&\#34;|&quot;/, '"').gsub(/&\#?39;?|&apos;/, '\'').gsub(/&\#?39;/, "'")
      end

      def abbreviate_US(line)
        line.gsub(/\bU(nited)?\.?\s*S(tates)?\b\.?/i, 'U.S.')
      end

      # Ordinal abbreviation
      def ordinals(line)
        # style guide says don't spell out ordinals in military or political divisions.
        look_ahead_reg = /\s(Canadian\sDivision|Canadian\sInfantry\sDivision|Armored\sDivision|Cavalry\sDivision|Infantry\sDivision|Marine\sDivision|Canadian\sDivision|Canadian\sInfantry\sDivision|Air\sDivision|Armored\sDivision|Cavalry\sDivision|Infantry\sDivision|Marine\sDivision|Canadian\sInfantry\sDivision|Armored\sDivision|Infantry\sDivision|Marine\sDivision|Canadian\sDivision|Canadian\sArmoured\sDivision|Air\sDivision|Armored\sDivision|Infantry\sDivision|Marine\sDivision|Canadian\sArmoured\sDivision|Air\sDivision|Armored\sDivision|Infantry\sDivision|Marine\sDivision|Armored\sDivision|Infantry\sDivision|Marine\sDivision|Canadian\sInfantry\sDivision|Air\sDivision|Armored\sDivision|Infantry\sDivision|Canadian\sInfantry\sDivision|Armored\sDivision|Infantry\sDivision|Armored\sDivision|Infantry\sDivision|Congressional\sDistrict|precinct)/i
        line.gsub(/\b1st\b(?!#{look_ahead_reg})/i, 'first').gsub(/\b2n?d\b(?!#{look_ahead_reg})/i, 'second').gsub(/\b3r?d\b(?!#{look_ahead_reg})/i, 'third').gsub(/\b4th\b(?!#{look_ahead_reg})/i, 'fourth').gsub(/\b5th\b(?!#{look_ahead_reg})/i, 'fifth').gsub(/\b6th\b(?!#{look_ahead_reg})/i, 'sixth').gsub(/\b7th\b(?!#{look_ahead_reg})/i, 'seventh').gsub(/\b8th\b(?!#{look_ahead_reg})/i, 'eighth').gsub(/\b9th\b(?!#{look_ahead_reg})/i, 'ninth').gsub(/\d{2,}(th\b|rd\b|st\b|nd\b)/i).each(&:downcase)
      end

      # 'St.' to 'Saint'
      def to_saint(line)
        line.gsub(SAINT_REGEX, 'Saint \1')
      end

      def street_types(line)
        STREET_TYPES.each { |key, value| line = line.gsub(key, value) }
        line
      end

      def normalize(value)
        return '' if value.nil? || value == ''

        value = value.strip
        value = value.gsub(/\\/, '')
        value = value.gsub(/(?<!\()\b([A-Za-z]+)\b(?!\)|[^\(]+\))/i).each(&:capitalize)
        value = value.gsub(/(?<=\')\bs\b/i, 's')
        value = value.gsub(/\bmac([A-Za-z]{2,})/i){ |m| 'Mac' + m.sub(/^mac/i, '').capitalize }
        value = value.gsub(/\bmc([A-Za-z]+)/i){ |m| 'Mc' + m.sub(/^mc/i, '').capitalize }
        value = value.gsub(/\b(of|and|or|the|is|at|an|as|in|to|from|for)\b/i).each(&:downcase) # UCLC exceptions
        value = value.gsub(/(?<!suite |No\. |Community |Apt\. )\ba\b(?!\.|\&|$)/i).each(&:downcase)
        value = value.gsub(/\b(westbound|eastbound|northbound|southbound)\b/i).each(&:downcase)
        value = value.gsub(/\b(iii?|iv|vii?i?|xv?ii?i?|xv|xiv|xix|xxi)\b|^([A-Z])/i).each(&:upcase)
        BUSINESS_ACRONYMS_SUBS.each { |k, v| value = value.gsub(k, v) }
        value
      end

      # Remove useless info before addresses
      def delete_pre_address(address)
        address = address.sub(/^\s*mail\:\s*/i, '')
        address.gsub(/.*\,\s+(\d+\b\s+\w)/i, '\1')
      end

      # Abbreviate compass points
      def compass_pt_abbr(address)
        address.gsub(/\bN(orth)?\b(?! #{STREET_TYPES_REGEX})\.*/i, 'N.').gsub(/\bE(ast)?\b(?! #{STREET_TYPES_REGEX})\.*/i, 'E.').gsub(/\bW(est)?\b(?! #{STREET_TYPES_REGEX})\.*/i, 'W.').gsub(/\bN(orth)?\.*\s*e(ast)?\b(?! #{STREET_TYPES_REGEX})\.*/i, 'N.E.').gsub(/\bN(orth)?\.*\s*w(est)?\b(?! #{STREET_TYPES_REGEX})\.*/i, 'N.W.').gsub(/\bS(outh)?\.*\s*e(ast)?\b(?! #{STREET_TYPES_REGEX})\.*/i, 'S.E.').gsub(/\bS(outh)?\.*\s*w(est)?\b(?! #{STREET_TYPES_REGEX})\.*/i, 'S.W.').gsub(/\b(?<!')S(outh)?\b(?! #{STREET_TYPES_REGEX})\.*/i, 'S.')
      end

      # 'Saint' to 'St.'
      def from_saint(line)
        line.gsub(/\bsaint\b/i, 'St.')
      end
    end
  end
end

