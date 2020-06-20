#Begin module for address-related methods.
module Address
  #corrects some odd Ohio abbreviation practices. I can't imagine this will be useful for many datasets.
  def Address.odd_OH_abbreviations(address)
    address = address.gsub(/\bWe\b/i, 'West').gsub(/\bIS\b/i, 'Interstate').gsub(/(\w)\-\s/i, '\1 - ').gsub(/\;(\w)/i, '; \1')
    return address
  end

  #Remove useless info before addresses
  def Address.delete_pre_address(address)
    address = address.sub(/^\s*mail\:\s*/i, '')
    address = address.gsub( /.*\,\s+(\d+\b\s+\w)/i, '\1' )
    return address
  end

  #Abbreviate compass points
  def Address.compass_pt_abbr(address)
    address = address.gsub( /\bN(orth)?\b(?! #{$street_types_regex})\.*/i, 'N.' ).gsub( /\bE(ast)?\b(?! #{$street_types_regex})\.*/i, 'E.' ).gsub( /\bW(est)?\b(?! #{$street_types_regex})\.*/i, 'W.' ).gsub( /\bN(orth)?\.*\s*e(ast)?\b(?! #{$street_types_regex})\.*/i, 'N.E.' ).gsub( /\bN(orth)?\.*\s*w(est)?\b(?! #{$street_types_regex})\.*/i, 'N.W.' ).gsub( /\bS(outh)?\.*\s*e(ast)?\b(?! #{$street_types_regex})\.*/i, 'S.E.' ).gsub( /\bS(outh)?\.*\s*w(est)?\b(?! #{$street_types_regex})\.*/i, 'S.W.' ).gsub( /\b(?<!')S(outh)?\b(?! #{$street_types_regex})\.*/i, 'S.' )
    return address
  end

  #Spell out and capitalize compass points
  def Address.compass_pt_full_cap(address)
    address = address.gsub( /\bN(orth)?\b\.*/i, 'North' ).gsub( /\bE(ast)?\b\.*/i, 'East' ).gsub( /\bW(est)?\b\.*/i, 'West' ).gsub( /\bN(orth)?\.*\s*e(ast)?\b\.*/i, 'Northeast' ).gsub( /\bN(orth)?\.*\s*w(est)?\b\.*/i, 'Northwest' ).gsub( /\bS(outh)?\.*\s*e(ast)?\b\.*/i, 'Southeast' ).gsub( /\bS(outh)?\.*\s*w(est)?\b\.*/i, 'Southwest' ).gsub( /\b(?<!')S(outh)?\b\.*/i, 'South' )
    return address
  end

  #Streets spelled out (except Ave., Blvd., and St.)
  def Address.street_types(line)
    $street_types.each do |key, value|
      line = line.gsub(key, value)
    end
    return line
  end

  def Address.street_types_beta(line)
    $street_types.each do |key, value|
      line = line.gsub(key, value).gsub(/(#{value}) #\s*([A-Za-z]+)/, '\1, No. \2')
    end
    return line
  end

  def Address.lions_addresses(street)
    street = '' if street == nil
    street = street.sub(/,.*/, '')
    return abbreviated_streets(street)
  end

  def Address.zip_strip(zip)
    zip == nil ? '' : zip.to_s.sub(/(-|(?<=\d{5})).*/, '').sub(/^(\d{4})$/, '0\1')
  end

  def Address.abbreviated_streets_postal(string)
    string = Address::abbreviated_streets(string)
    string = Address::states_to_postal_aggressive(string)
    string = string.sub(/\b(N|S)\.(E|W)\b\./i, '\1\2')
    return string
  end

  def Address.second_comma_states_postal(string)
    string.match(/([^,]+),([^,]+),([^,]+)(?:,(.*)|\s*$)/i){|m|
      string = "#{Address::street_substitutions(m[1])}, #{normalize(m[2])}, #{Address::states_to_postal(m[3])}, #{Address::street_substitutions(m[4])}"
    }
    string = string.sub(/^\s*care of\s{1,}(?=\d)/, '')
    string = string.sub(/,\s*$/, '')
    string = string.sub(/\s{2,}/, ' ')
    string = string.strip
    return string
  end

  def Address.second_comma_states_postal_revamp(string)
    string.match(/([^,]+),([^,]+),([^,]+)(?:,(.*)|\s*$)/i){|m|
      string = "#{Address::street_substitutions(m[1])}, #{normalize(m[2])}, #{Address::states_to_postal(m[3])}, #{Address::street_substitutions(m[4])}"
    }
    string = string.sub(/^\s*care of\s{1,}/, '')
    string = string.gsub( /(^\s*#*\s*)(?=\d+)/, '' ).gsub( /##/, 'No.' ).gsub( /(\bUnit\b|\bs(?:ui)?te\b|\bap(?:artmen)?t\b)\.?(?:\,)?\s*(?:#|No\.)?\s*(\b\d+\b)/i, '\1 \2' ).gsub( /#unit/, 'Unit' ).gsub( /#\s*(\d+\w{0,1})\s*(?:&|and)\s*(\d+\w{0,1})/i, 'Units \1 and \2' ).gsub( /#\s*(\d+)\b/, 'No. \1' ).gsub(/(?<=.|\s)(?:#|No\.)\s*(\b\d+\b)/i, 'No. \1' ).gsub( /(?:#|No\.)\s*(\d+\-?[a-zA-Z]|[a-zA-Z]\-?\d+)/i, 'Unit \1' ).gsub( /(?:#|No\.)\s*([A-Za-z])\s*(\d+\-?[a-zA-Z]?)/i, 'Unit \1\2' )
    string = string.gsub(/ #\s*([A-Za-z])\b/, ', No. \1')
    string = string.sub(/\b(N|S)\.(E|W)\b\./i, '\1\2')
    string = string.sub(/,\s*$/, '')
    string = string.sub(/\s{2,}/, ' ')
    string = string.strip
    return string
  end

  def Address.remove_values_from_address(address, city, state, zip)
    address = address.gsub(/,\s*#{city}\s*\b/i, '')
    address = address.gsub(/,\s*#{state}\s*\b/i, '')
    address = address.gsub(/,\s*#{zip}-?\d*\s*\b/i, '')
    address = address.gsub(/,\s*#{zip.gsub(/-?\d*\s*\b/, '')}-?\d*\s*\b/i, '')
  end

  def Address.street_substitutions(street)
    return '' if street == nil or street == '' or street == /^\s*NULL\s*$/i
    street = html_entities(street)
    street = Address.delete_pre_address(street)
    street = ordinals(street)
    street = normalize(street)
    street = street.gsub(/(?<! )\(/, ' (')
    street = street.gsub(/([NESW])\.FM/, '\1. FM')
    street = street.gsub(/\bHCR\b/i, 'HCR')
    street = street.gsub(/\bapt\b\.(\b[A-Za-z0-9]{1,2}\b)/i, 'Apt. \1')
    street = street.sub(/\bRR(\b|\d+)\s*/i, 'Rural Route \1 ')
    street = street.sub(/([\,][\.\,]*)\s*$/, '')
    street = street.sub(/^\s*[\,\.\-\s]+\s*/, '')
    street = street.gsub(/(?<!\b1|\bc)\//i, ' and ')
    street = street.gsub(/\bwb\b/i, 'westbound')
    street = street.gsub(/\beb\b/i, 'eastbound')
    street = street.gsub(/\bnb\b/i, 'northbound')
    street = street.gsub(/\bsb\b/i, 'southbound')
    street = street.gsub(/\bP\.?\s*O\b\.? drawer\b/i, 'P.O. Drawer')
    street = street.gsub(/^P(?:\.|ost)?\s*(?:O(?:\.|ffice)?|M(?:\.|ail)?)\s*(?:B(?:o(?:x|z))?|D(?:\.|rawer)?)|^P(?:\.|ost)?\s*O(?:\.|ffice)?\s*(\d+)\b|^\s*Box\b\s*/i, 'P.O. Box \1')
    street = Address.street_types_beta(street)
    street = street.gsub(/(\d+\b.+\b)(\bave?nue\b|\bavn?\b\.*|\bave\b\.*)/i, '\1Ave.').gsub(/(\d+\b.+\b)(\bBo?u?le?va?r?d\b\.*|\bBoulv?\b\.*)/i, '\1Blvd.').gsub(/(\d+\b.+\b)\bst(reet)?\b\.*/i, '\1St.')
    street = street.gsub(/,?\s+#\s*([A-Za-z])\b/, ', No. \1')
    #Add comma before 'Unit', 'No.', or 'Lot'
    street = street.gsub(/,?\s*\bs(ui)?te\b\.?/i, ', Suite').gsub(/,?\s*\bap(artmen)?t\b\.?/i, ', Apt.').gsub( /\bSuite\s*([A-Za-z0-9\-]{1,5})\s(?:&|and)\s([A-Za-z0-9\-]{1,5})/i, 'Suites \1 and \2' )
    street = street.gsub( /,?\s*\b(Unit\b|No\b\.|Lot\b)/i, ', \1' )
    street = street.gsub(/(\bUnit\b|\bs(?:ui)?te\b|\bap(?:artmen)?t\b)\.?, No. ([A-Za-z])\b/i, '\1 \2')
    street = Address.compass_pt_abbr(street)
    street = street.gsub(/\bU(nited)?\.?\s*S(tates)?\b\.?/i, 'U.S.' )
    street = Name.to_saint(street)
    street = Name.from_saint(street)
    street = street.gsub( /\(?Exit\s(\d+)\)?/i, 'at exit \1' )
    return street
  end

  def Address.assemble_address_from_values(county_prefix, num, dir, street, street_type, unit, city_id_or_name, zip)
    dir = false if dir == ''
    unit = false if unit == ''

    if city_id_or_name.is_a?(Integer)
      route = Route.new(county_prefix)
      city_check = route.client.query("select name from #{route.stage_db}.cities where id = #{city_id_or_name}")
      if !city_check.first
        city = ''
      else
        city = city_check.first['name']
      end
      route.web_client.close if route
      route.client.close if route
    else
      city = city_id_or_name
    end

    address = "#{num}#{dir ? " #{dir}" : ""} #{street} #{street_type}#{unit ? " #{unit}" : ""}, #{city} #{zip != 0 ? zip : nil}".strip
    address = Address::abbreviated_streets(address)

    return address
  end

  #method corresponding to abbreviated_streets algo
  def Address.abbreviated_streets(street)
    street = '' if street == nil
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

    #Replaces html entities
    abb_street = html_entities(street)

    #P.O. Boxes handled
    #abb_street = abb_street.gsub( /((?:P\.?\s*O\.?)?\s+Box\s+[0-9A-Za-z]+)\,\s+(.+)/i, '\2, \1' ).gsub( /(?:P\.?\s*O\.?\s?)?\sbox\s+([0-9A-Za-z]+)/i, 'P.O. Box \1' )
    abb_street = abb_street.gsub(/\bP\.?\s*O\b\.? box\b/i, 'P.O. Box')
    abb_street = abb_street.gsub(/\bP\.?\s*O\b\.? drawer\b/i, 'P.O. Drawer')
    #U.S.
    abb_street = abbreviate_US(abb_street)

    #ordinals
    abb_street = ordinals(abb_street)

    #St. to Saint
    abb_street = Name.to_saint(abb_street)
    #Abbreviates Ave., St., and Blvd. according to AP guidelines.
    abb_street = Address.street_types(abb_street)
    abb_street = abb_street.gsub(/(\d+\b.+\b)(\bave?nue\b|\bavn?\b\.*|\bave\b\.*)/i, '\1Ave.').gsub(/(\d+\b.+\b)(\bBo?u?le?va?r?d\b\.*|\bBoulv?\b\.*)/i, '\1Blvd.').gsub(/(\d+\b.+\b)\bst(reet)?\b\.*/i, '\1St.')
    abb_street = abb_street.gsub(/\bst\b(?!\.)/i, 'Street')
    abb_street = abb_street.gsub(/\bave\b(?!\.)/i, 'Avenue')
    #Spells out all remaining street names according to AP guidelines.

    abb_street = normalize(abb_street)

    abb_street = abb_street.gsub(/\ba\b/, 'A')


    #Eliminates hashes in addresses.
    abb_street = abb_street.gsub( /(^\s*#*\s*)(?=\d+)/, '' ).gsub( /##/, 'No.' ).gsub( /(\bUnit\b|\bs(?:ui)?te\b|\bap(?:artmen)?t\b)\.?(?:\,)?\s*(?:#|No\.)?\s*(\b\d+\b)/i, '\1 \2' ).gsub( /#unit/, 'Unit' ).gsub( /#\s*(\d+\w{0,1})\s*(?:&|and)\s*(\d+\w{0,1})/i, 'Units \1 and \2' ).gsub( /#\s*(\d+)\b/, 'No. \1' ).gsub(/(?<=.|\s)(?:#|No\.)\s*(\b\d+\b)/i, 'No. \1' ).gsub( /(?:#|No\.)\s*(\d+\-?[a-zA-Z]|[a-zA-Z]\-?\d+)/i, 'Unit \1' ).gsub( /(?:#|No\.)\s*([A-Za-z])\s*(\d+\-?[a-zA-Z]?)/i, 'Unit \1\2' )

    $street_types.each do |key, value|
      abb_street = abb_street.gsub(/(#{value}) #\s*([A-Za-z]+)/, '\1, No. \2')
    end

    abb_street = abb_street.gsub(/ #\s*([A-Za-z])\b/, ', No. \1')
    #Add comma before 'Unit', 'No.', or 'Lot'
    abb_street = abb_street.gsub( /,?\s*\b(Unit\b|No\b\.|Lot\b)/i, ', \1' )
    abb_street = abb_street.gsub(/(\bUnit\b|\bs(?:ui)?te\b|\bap(?:artmen)?t\b)\.?, No. ([A-Za-z])\b/i, '\1 \2')

    #Eliminates unnecessary information from before an address.
    abb_street = Address.delete_pre_address(abb_street)

    #Suites and apartments
    #abb_street = abb_street.gsub( /(?<=\,)\s*\bs(ui)?te\.*/i, ' Suite' ).gsub( /(?<!\,)\s\bs(ui)?te\.*/i, ', Suite' ).gsub( /(?<!\,)\bs(ui)?te\.*/i, ', Suite' ).gsub( /(?<=\,)\s*\bap(artmen)?t\.*/i, ' Apt.' ).gsub( /(?<!\,)\s\bap(artmen)?t\.*/i, ', Apt.' ).gsub( /(?<!\,)\bap(artmen)?t\.*/i, ', Apt.' ).gsub( /\bSuite\s*([A-Za-z0-9\-]{1,5})\s(?:&|and)\s([A-Za-z0-9\-]{1,5})/i, 'Suites \1 and \2' )
    abb_street = abb_street.gsub(/,?\s*\bs(ui)?te\b\.?/i, ', Suite').gsub(/,?\s*\bap(artmen)?t\b\.?/i, ', Apt.').gsub( /\bSuite\s*([A-Za-z0-9\-]{1,5})\s(?:&|and)\s([A-Za-z0-9\-]{1,5})/i, 'Suites \1 and \2' )

    #Abbreviating compass points
    abb_street = Address.compass_pt_abbr(abb_street)

    #remove periods from suites, units, etc where they've been mistaken for cardinal directions
    abb_street = abb_street.gsub(/(\bUnit\b|\bs(?:ui)?te\b|\bap(?:artmen)?t\b)\.? ([NESWnesw])\./i, '\1 \2')

    #Exits
    abb_street = abb_street.gsub( /\(?Exit\s(\d+)\)?/i, 'at exit \1' )
    #Finishing touches (Or: things that need to be done near the end of the street abbreviation process)
    abb_street = abb_street.gsub( /P\.o\./, 'P.O.' )				#capitalizes 'o' in 'P.o.'
    if abb_street =~ /\b\d+\-?[a-z]\b/							#capitalizes, e.g., 'c' in '7c'
      unit = abb_street[ /\b\d+\-?[a-z]\b/ ].upcase
      abb_street = abb_street.gsub( /\b\d+\-?[a-z]\b/, unit )
    end
    abb_street = abb_street.gsub( /\bUs\b/, 'US' )					#Us to US
    abb_street = abb_street.gsub( /\bS\.e\./, 'S.E.' ).gsub( /\bS\.w\./, 'S.W.' ).gsub( /\bN\.e\./, 'N.E.' ).gsub( /\bN\.w\./, 'N.W.' )

    #'Saint' to 'St.'
    abb_street = Name.from_saint(abb_street)

    $states_to_AP.each do |key, value|
      abb_street = abb_street.gsub(/,?\s*(#{key})\s*$/i, ', \1')
    end

    $states_to_AP.each do |key, value|
      abb_street = abb_street.gsub(/#{key}(?! #{$street_types_regex})(?!,? #{$states_to_AP_regex})/i, value)
    end

    abb_street = abb_street.gsub(/\.\./, '.') #we'll need to track the problem here down, but no time today.
    return abb_street

  end

  def Address.block_address(line)
    line = abbreviated_streets(line)
    line = line.sub(/^(\d+)(\d{2})\.?\d*\b/, 'in the \100 block of')
    line = line.sub(/^(\d{1,2})\.?\d*\b/, 'in the 0 block of')
    if !line[/^in/] and !line[/^\s*$/]
      line = "at #{line}"
    end
    line = line.sub(/^\s*|\s*$/, '')
    return line
  end

  def Address.miami_block_addresses(string)

    string = Address::crime_address(string)

    $metrorail_stations.each do |k, v|
      string = string.gsub(k, v)
    end
    output = nil
    string.match(/(\d+) block (.*)/i){|m|
      output = "in the #{m[0].sub(/block of block/i, 'block of')}"
    }
    output = "near #{Address::crime_address(string)}" if output == nil
    output = output.sub(/^near the\b/i, 'near the')
    output = output.sub(/^near in the\b/i, 'in the')
    output = output.gsub(/\s{2,}/, ' ')
    output = output.strip
    return output
  end

  def Address.erlanger_pd_adjustments(line)
    line = line.sub(/ (erlanger(?! rd| road)|crescent springs(?! ro?a?d)|elsmere|kenton county).*/i, '')
    return block_address(line)
  end

  #used to convert lines like '84 State Street, Suite 550, Boston, MA 02109' to '84 State Street, Suite 550'
  def Address.drop_city_state_zip(line)
    line = line.sub(/\,[^,]+\,\s+\w\w\s+\d{5}\z/i, '')
    return line
  end

  def Address.crime_address(line)

    #Replaces html entities
    crime_address = html_entities(line)

    #Normalize before adding "in the...block of"
    crime_address = normalize(crime_address)

    #Odd stuff
    crime_address = crime_address.gsub( /CFRC/i, 'Central Florida Racing Complex' ).gsub( /\bHOMELESS\s+LKA\b/i, 'last known as homeless' ).gsub( /\bHOMELESS\b/i, 'homeless' )

    #P.O. Boxes handled
    crime_address = crime_address.gsub( /((?:P\.?O\.?)?\s+Box\s+[0-9A-Za-z]+)\,\s+(.+)/i, '\2, \1' ).gsub( /(?:P\.?O\.?\s?)?\sbox\s+([0-9A-Za-z]+)/i, 'P.O. Box \1' )

    #U.S.
    crime_address = abbreviate_US(crime_address)

    #ordinals
    crime_address = ordinals(crime_address)

    #St. to Saint
    crime_address = Name.to_saint(crime_address)

    #Spell out and capitalize compass points
    crime_address = Address.compass_pt_full_cap(crime_address)

    #Spell out and capitalize street names
    crime_address = Address.street_types(crime_address)
    crime_address = crime_address.gsub(/(\bave?nue\b|\baven?\b|\bave\b)\.*/i, 'Avenue').gsub(/(\bBo?u?le?va?r?d\b\.*|\bBoulv?\b\.*)/i, 'Boulevard').gsub(/\bst(reet)?\b\.*/i, 'Street')

    #Delete across from
    crime_address = crime_address.gsub( /^\s*across\sfrom\s+/i, '' )

    #Delete block range
    crime_address = crime_address.gsub( /\^s*(\d+)\-\d+\s/i, '\1 ' )

    #Delete city, state and apartment number
    if crime_address != /fm\s\d+\s*\Z|P\.O\./im and crime_address != /\b(SR|State Route|I-?)\s*\d+\s*\Z/im
      crime_address = crime_address.gsub(/(?:[A-Z]*)\.?\d+,?\s*\Z/, '' )
    end
    crime_address = crime_address.gsub( /\bAPT(\b|\.).*/i, ' ).gsub( /,?\s*Apt-\d+\s*/im, '' ).gsub( /,\s*[A-Z]{2}\s*$/im, ' ).gsub( /\bapartment.*/i, ' ).gsub( /,[^,]*\Z/i, ' )

    #Main stuff here
    if crime_address =~ /\A\d+\b/
      crime_address = crime_address.gsub( /\A(\d+)\d{2}\b\s+(.*)\Z/i, 'in the \100 block of \2' ).gsub( /\A\b\d{1,2}\b/i, 'on' )
    end

    #Remove 'Lot', 'Unit', 'Suite' at end of crime address
    crime_address = crime_address.gsub( /(?<=#{$street_suffixes})(Lot|Unit|S(ui)?te).*/i, '' )

    #'Saint' to 'St.'
    crime_address = Name.from_saint(crime_address)

    #Finishing touches
    crime_address = crime_address.gsub( /\Aon\s(?=(last\sknown|homeless))/i, '' )

    return crime_address

  end

  def Address.states_to_AP(state)
    state = '' if state == nil
    #State name, abbreviation or mispelling to AP
    #state = state.gsub(/\b(?:U\.?S\.?-)?(?:Ala?(bama)?|All?abamm?a)\b\.?/i, 'Ala.').gsub(/\b(?:U\.?S\.?-)?(?:A(?:las|(?:lask|k))a?|Alsaka)\b\.?/i, 'Alaska').gsub(/\b(?:U\.?S\.?-)?(?:A(?:riz|z)(?:ona)?|Ar(?:zinoa|izonia))\b\.?/i, 'Ariz.').gsub(/\b(?:U\.?S\.?-)?Ark?(?:ansas)?\b\.?/i, 'Ark.').gsub(/\b(?:U\.?S\.?-)?(?:(?:Ca|CF|cal|cali|calif)(?:ornia)?|Califronia)\b\.?/i, 'Calif.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Co|Colo?|CL)(lorado)?|C(?:alo|ola|ala)rado)\b\.?/i, 'Colo.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Conn|Ct)(?:ecticut)?|connec?tt?icut?t)\b\.?/i, 'Conn.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Del?|DL)(?:aware)?|delawere)\b\.?/i, 'Del.' ).gsub(/\b(?:U\.?S\.?-)?(?:Wash(ington)\b\.?)?\s*\bD\.?(?:istrict\s+of\s+)?C\.?(?:olumbia)?\b\.?/i, 'D.C.' ).gsub(/\b(?:U\.?S\.?-)?(?:Fl(?:or(?!a\b))?(?:id?)?a?|Flori?y?di?as?)\b\.?/i, 'Fla.').gsub(/\b(?:U\.?S\.?-)?(?:G(?:eorgi)?a|Georgei?a)\b\.?/i, 'Ga.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Hi|HA|Hawaii)|Ha?o?wa?a?ii?)\b\.?/i, 'Hawaii' ).gsub(/\b(?:U\.?S\.?-)?(?:Ida?(?:ho)?|ida?e?hoe?)\b\.?/i, 'Idaho' ).gsub(/\b(?:U\.?S\.?-)?(?:Ill?(?:inoi)?\'?s?|illi?a?noise)\b\.?/i, 'Ill.' ).gsub(/\b(?:U\.?S\.?-)?Ind?(?:iana)?\b\.?/i, 'Ind.' ).gsub(/\b(?:U\.?S\.?-)?(?:I(?:ow?)?a|Iowha|ioaw|iwoa)\b\.?/i, 'Iowa' ).gsub(/\b(?:U\.?S\.?-)?(?:ka|ks|kans?)(as?)?\b\.?/i, 'Kan.' ).gsub(/\b(?:U\.?S\.?-)?(?:K(?:ent?|y)(?:ucky)?|kentuc?k?y)\b\.?/i, 'Ky.' ).gsub(/\b(?:U\.?S\.?-)?(?:L(?:ouisian)?a|louiseiana)\b\.?/i, 'La.' ).gsub(/\b(?:U\.?S\.?-)?(?:M(?:ain)?e|Mi?ai?ne?)\b\.?/i, 'Maine' ).gsub(/\b(?:U\.?S\.?-)?(?:M(?:arylan)?d|Marr?y\s*land)\b\.?/i, 'Md.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Ma|Mass)(achusetts)?|mass?achuss?ett?s)\b\.?/i, 'Mass.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Mi(?:ch)?|Mc)(?:igan)?|michi?a?ga?i?n)\b\.?/i, 'Mich.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Mn|Minn)(?:esota)?|Minesota)\b\.?/i, 'Minn.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:MS|Miss)(?:issippi)?|mississipi)\b\.?/i, 'Miss.' ).gsub(/\b(?:U\.?S\.?-)?(?:M(?:iss)?o(?:uri)?|Miss?ouri?y?)\b\.?/i, 'Mo.' ).gsub(/\b(?:U\.?S\.?-)?M(?:on)?t(?:ana)?\b\.?/i, 'Mont.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Ne(b|br)?|Nb)(?:aska)?|nebrasck?a)\b\.?/i, 'Nebr.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Ne?v)(?:ada)?|new?vadaa?)\b\.?/i, 'Nev.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?\.?\s*H(?:ampshire)?\b\.?/i, 'N.H.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?\.?\s*J(?:ersey)?\b\.?/i, 'N.J.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?\.?\s*M(?:ex|exico)?\b\.?/i, 'N.M.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?Y(?:ork)?\b\.?/i, 'N.Y.' ).gsub(/\b(?:U\.?S\.?-)?N(?:orth\s+)?\.?\s*C(?:ar|arole?ina)?\b\.?/i, 'N.C.' ).gsub(/\b(?:U\.?S\.?-)?N(?:o|orth\s+)?\.?\s*D(?:ak|akota)?\b\.?/i, 'N.D.' ).gsub(/\b(?:U\.?S\.?-)?(?:O(?:hio)|oiho)\b\.?/i, 'Ohio' ).gsub(/\b(?:U\.?S\.?-)?(?:Ok(?:la)?(?:homa)?|okalahoma)\b\.?/i, 'Okla.' ).gsub(/\b(?:U\.?S\.?-)?(?:Or(?:e|eg)?(?:on)?|orgon)\b\.?/i, 'Ore.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:PA|Penna?)(?:sylvania)?|pensylvania)\b\.?/i, 'Pa.' ).gsub(/\b(?:U\.?S\.?-)?(?:R(?:hode\s+)\.?\s*I(?:sland)?|rh?oa?de?\sisland)\b\.?/i, 'R.I.' ).gsub(/\b(?:U\.?S\.?-)?S(?:outh\s+)?\.?\s*C(?:ar)?(?:olin?a?)?\b\.?/i, 'S.C.' ).gsub(/\b(?:U\.?S\.?-)?S(?:o\s*|outh\s+)?\.?\s*D(?:ak|akota)?\b\.?/i, 'S.D.' ).gsub(/\b(?:U\.?S\.?-)?(?:Tn|Tenn)(?:i?e?ss?ee?)?\b\.?/i, 'Tenn.' ).gsub(/\b(?:U\.?S\.?-)?(?:Te?x)(a?e?i?s)?\b\.?/i, 'Texas' ).gsub(/\b(?:U\.?S\.?-)?Ut(?:ah|es|ar)?\b\.?/i, 'Utah' ).gsub(/\b(?:U\.?S\.?-)?V(?:ermon)?t\b\.?/i, 'Vt.' ).gsub(/\b(?:U\.?S\.?-)?(?:Wash|Wa|Wn)(?:ington)?\b\.?/i, 'Wash.' ).gsub(/\b(?:U\.?S\.?-)?W(?:est\s+)?\.?\s*V(?:irg|a)?(?:i?ni?a)?\b\.?/i, 'W.Va.' ).gsub(/\b(?:U\.?S\.?-)?V(?:irg|a)(?:i?ni?a)?\b\.?/i, 'Va.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Wis?c?(?:onsin)?)|wisconson)\b\.?/i, 'Wis.' ).gsub(/\b(?:U\.?S\.?-)?(?:Wyo?(?:ming)?|wh?y?i?oming)\b\.?/i, 'Wyo.' )
    $states_to_AP.each do |key, value|
      unless state == nil
        state = state.gsub(/#{key}(?! #{$street_types_regex})(?!,? #{$states_to_AP_regex})/, value)
      end
    end

    #exceptions
    unless state == nil
      state = state.gsub(/del\.(\s*[^\s\d$])/i, 'Del\1')
    end

    return state
  end

  def Address.states_to_postal(state)
    state = '' if state == nil
    state = state.sub(/,\s*$/, '')
    #State name, abbreviation or mispelling to AP
    #state = state.gsub(/\b(?:U\.?S\.?-)?(?:Ala?(bama)?|All?abamm?a)\b\.?/i, 'Ala.').gsub(/\b(?:U\.?S\.?-)?(?:A(?:las|(?:lask|k))a?|Alsaka)\b\.?/i, 'Alaska').gsub(/\b(?:U\.?S\.?-)?(?:A(?:riz|z)(?:ona)?|Ar(?:zinoa|izonia))\b\.?/i, 'Ariz.').gsub(/\b(?:U\.?S\.?-)?Ark?(?:ansas)?\b\.?/i, 'Ark.').gsub(/\b(?:U\.?S\.?-)?(?:(?:Ca|CF|cal|cali|calif)(?:ornia)?|Califronia)\b\.?/i, 'Calif.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Co|Colo?|CL)(lorado)?|C(?:alo|ola|ala)rado)\b\.?/i, 'Colo.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Conn|Ct)(?:ecticut)?|connec?tt?icut?t)\b\.?/i, 'Conn.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Del?|DL)(?:aware)?|delawere)\b\.?/i, 'Del.' ).gsub(/\b(?:U\.?S\.?-)?(?:Wash(ington)\b\.?)?\s*\bD\.?(?:istrict\s+of\s+)?C\.?(?:olumbia)?\b\.?/i, 'D.C.' ).gsub(/\b(?:U\.?S\.?-)?(?:Fl(?:or(?!a\b))?(?:id?)?a?|Flori?y?di?as?)\b\.?/i, 'Fla.').gsub(/\b(?:U\.?S\.?-)?(?:G(?:eorgi)?a|Georgei?a)\b\.?/i, 'Ga.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Hi|HA|Hawaii)|Ha?o?wa?a?ii?)\b\.?/i, 'Hawaii' ).gsub(/\b(?:U\.?S\.?-)?(?:Ida?(?:ho)?|ida?e?hoe?)\b\.?/i, 'Idaho' ).gsub(/\b(?:U\.?S\.?-)?(?:Ill?(?:inoi)?\'?s?|illi?a?noise)\b\.?/i, 'Ill.' ).gsub(/\b(?:U\.?S\.?-)?Ind?(?:iana)?\b\.?/i, 'Ind.' ).gsub(/\b(?:U\.?S\.?-)?(?:I(?:ow?)?a|Iowha|ioaw|iwoa)\b\.?/i, 'Iowa' ).gsub(/\b(?:U\.?S\.?-)?(?:ka|ks|kans?)(as?)?\b\.?/i, 'Kan.' ).gsub(/\b(?:U\.?S\.?-)?(?:K(?:ent?|y)(?:ucky)?|kentuc?k?y)\b\.?/i, 'Ky.' ).gsub(/\b(?:U\.?S\.?-)?(?:L(?:ouisian)?a|louiseiana)\b\.?/i, 'La.' ).gsub(/\b(?:U\.?S\.?-)?(?:M(?:ain)?e|Mi?ai?ne?)\b\.?/i, 'Maine' ).gsub(/\b(?:U\.?S\.?-)?(?:M(?:arylan)?d|Marr?y\s*land)\b\.?/i, 'Md.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Ma|Mass)(achusetts)?|mass?achuss?ett?s)\b\.?/i, 'Mass.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Mi(?:ch)?|Mc)(?:igan)?|michi?a?ga?i?n)\b\.?/i, 'Mich.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Mn|Minn)(?:esota)?|Minesota)\b\.?/i, 'Minn.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:MS|Miss)(?:issippi)?|mississipi)\b\.?/i, 'Miss.' ).gsub(/\b(?:U\.?S\.?-)?(?:M(?:iss)?o(?:uri)?|Miss?ouri?y?)\b\.?/i, 'Mo.' ).gsub(/\b(?:U\.?S\.?-)?M(?:on)?t(?:ana)?\b\.?/i, 'Mont.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Ne(b|br)?|Nb)(?:aska)?|nebrasck?a)\b\.?/i, 'Nebr.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Ne?v)(?:ada)?|new?vadaa?)\b\.?/i, 'Nev.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?\.?\s*H(?:ampshire)?\b\.?/i, 'N.H.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?\.?\s*J(?:ersey)?\b\.?/i, 'N.J.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?\.?\s*M(?:ex|exico)?\b\.?/i, 'N.M.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?Y(?:ork)?\b\.?/i, 'N.Y.' ).gsub(/\b(?:U\.?S\.?-)?N(?:orth\s+)?\.?\s*C(?:ar|arole?ina)?\b\.?/i, 'N.C.' ).gsub(/\b(?:U\.?S\.?-)?N(?:o|orth\s+)?\.?\s*D(?:ak|akota)?\b\.?/i, 'N.D.' ).gsub(/\b(?:U\.?S\.?-)?(?:O(?:hio)|oiho)\b\.?/i, 'Ohio' ).gsub(/\b(?:U\.?S\.?-)?(?:Ok(?:la)?(?:homa)?|okalahoma)\b\.?/i, 'Okla.' ).gsub(/\b(?:U\.?S\.?-)?(?:Or(?:e|eg)?(?:on)?|orgon)\b\.?/i, 'Ore.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:PA|Penna?)(?:sylvania)?|pensylvania)\b\.?/i, 'Pa.' ).gsub(/\b(?:U\.?S\.?-)?(?:R(?:hode\s+)\.?\s*I(?:sland)?|rh?oa?de?\sisland)\b\.?/i, 'R.I.' ).gsub(/\b(?:U\.?S\.?-)?S(?:outh\s+)?\.?\s*C(?:ar)?(?:olin?a?)?\b\.?/i, 'S.C.' ).gsub(/\b(?:U\.?S\.?-)?S(?:o\s*|outh\s+)?\.?\s*D(?:ak|akota)?\b\.?/i, 'S.D.' ).gsub(/\b(?:U\.?S\.?-)?(?:Tn|Tenn)(?:i?e?ss?ee?)?\b\.?/i, 'Tenn.' ).gsub(/\b(?:U\.?S\.?-)?(?:Te?x)(a?e?i?s)?\b\.?/i, 'Texas' ).gsub(/\b(?:U\.?S\.?-)?Ut(?:ah|es|ar)?\b\.?/i, 'Utah' ).gsub(/\b(?:U\.?S\.?-)?V(?:ermon)?t\b\.?/i, 'Vt.' ).gsub(/\b(?:U\.?S\.?-)?(?:Wash|Wa|Wn)(?:ington)?\b\.?/i, 'Wash.' ).gsub(/\b(?:U\.?S\.?-)?W(?:est\s+)?\.?\s*V(?:irg|a)?(?:i?ni?a)?\b\.?/i, 'W.Va.' ).gsub(/\b(?:U\.?S\.?-)?V(?:irg|a)(?:i?ni?a)?\b\.?/i, 'Va.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Wis?c?(?:onsin)?)|wisconson)\b\.?/i, 'Wis.' ).gsub(/\b(?:U\.?S\.?-)?(?:Wyo?(?:ming)?|wh?y?i?oming)\b\.?/i, 'Wyo.' )
    stateout = state
    $states_to_postal.each do |key, value|
      unless state == nil
        state = state.gsub(/#{key}(?! #{$street_types_regex})(?!,? #{$states_to_AP_regex})/, value)
      end

    end
    state = state.gsub(/(^\s*|\s*$)/, '')
    state = state[/^\w{2}$/] ? state : stateout
    return state
  end

  def Address.states_to_postal_aggressive(state)
    state = '' if state == nil
    #State name, abbreviation or mispelling to AP
    #state = state.gsub(/\b(?:U\.?S\.?-)?(?:Ala?(bama)?|All?abamm?a)\b\.?/i, 'Ala.').gsub(/\b(?:U\.?S\.?-)?(?:A(?:las|(?:lask|k))a?|Alsaka)\b\.?/i, 'Alaska').gsub(/\b(?:U\.?S\.?-)?(?:A(?:riz|z)(?:ona)?|Ar(?:zinoa|izonia))\b\.?/i, 'Ariz.').gsub(/\b(?:U\.?S\.?-)?Ark?(?:ansas)?\b\.?/i, 'Ark.').gsub(/\b(?:U\.?S\.?-)?(?:(?:Ca|CF|cal|cali|calif)(?:ornia)?|Califronia)\b\.?/i, 'Calif.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Co|Colo?|CL)(lorado)?|C(?:alo|ola|ala)rado)\b\.?/i, 'Colo.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Conn|Ct)(?:ecticut)?|connec?tt?icut?t)\b\.?/i, 'Conn.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Del?|DL)(?:aware)?|delawere)\b\.?/i, 'Del.' ).gsub(/\b(?:U\.?S\.?-)?(?:Wash(ington)\b\.?)?\s*\bD\.?(?:istrict\s+of\s+)?C\.?(?:olumbia)?\b\.?/i, 'D.C.' ).gsub(/\b(?:U\.?S\.?-)?(?:Fl(?:or(?!a\b))?(?:id?)?a?|Flori?y?di?as?)\b\.?/i, 'Fla.').gsub(/\b(?:U\.?S\.?-)?(?:G(?:eorgi)?a|Georgei?a)\b\.?/i, 'Ga.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Hi|HA|Hawaii)|Ha?o?wa?a?ii?)\b\.?/i, 'Hawaii' ).gsub(/\b(?:U\.?S\.?-)?(?:Ida?(?:ho)?|ida?e?hoe?)\b\.?/i, 'Idaho' ).gsub(/\b(?:U\.?S\.?-)?(?:Ill?(?:inoi)?\'?s?|illi?a?noise)\b\.?/i, 'Ill.' ).gsub(/\b(?:U\.?S\.?-)?Ind?(?:iana)?\b\.?/i, 'Ind.' ).gsub(/\b(?:U\.?S\.?-)?(?:I(?:ow?)?a|Iowha|ioaw|iwoa)\b\.?/i, 'Iowa' ).gsub(/\b(?:U\.?S\.?-)?(?:ka|ks|kans?)(as?)?\b\.?/i, 'Kan.' ).gsub(/\b(?:U\.?S\.?-)?(?:K(?:ent?|y)(?:ucky)?|kentuc?k?y)\b\.?/i, 'Ky.' ).gsub(/\b(?:U\.?S\.?-)?(?:L(?:ouisian)?a|louiseiana)\b\.?/i, 'La.' ).gsub(/\b(?:U\.?S\.?-)?(?:M(?:ain)?e|Mi?ai?ne?)\b\.?/i, 'Maine' ).gsub(/\b(?:U\.?S\.?-)?(?:M(?:arylan)?d|Marr?y\s*land)\b\.?/i, 'Md.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Ma|Mass)(achusetts)?|mass?achuss?ett?s)\b\.?/i, 'Mass.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Mi(?:ch)?|Mc)(?:igan)?|michi?a?ga?i?n)\b\.?/i, 'Mich.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Mn|Minn)(?:esota)?|Minesota)\b\.?/i, 'Minn.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:MS|Miss)(?:issippi)?|mississipi)\b\.?/i, 'Miss.' ).gsub(/\b(?:U\.?S\.?-)?(?:M(?:iss)?o(?:uri)?|Miss?ouri?y?)\b\.?/i, 'Mo.' ).gsub(/\b(?:U\.?S\.?-)?M(?:on)?t(?:ana)?\b\.?/i, 'Mont.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Ne(b|br)?|Nb)(?:aska)?|nebrasck?a)\b\.?/i, 'Nebr.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Ne?v)(?:ada)?|new?vadaa?)\b\.?/i, 'Nev.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?\.?\s*H(?:ampshire)?\b\.?/i, 'N.H.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?\.?\s*J(?:ersey)?\b\.?/i, 'N.J.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?\.?\s*M(?:ex|exico)?\b\.?/i, 'N.M.' ).gsub(/\b(?:U\.?S\.?-)?N(?:ew\s+)?Y(?:ork)?\b\.?/i, 'N.Y.' ).gsub(/\b(?:U\.?S\.?-)?N(?:orth\s+)?\.?\s*C(?:ar|arole?ina)?\b\.?/i, 'N.C.' ).gsub(/\b(?:U\.?S\.?-)?N(?:o|orth\s+)?\.?\s*D(?:ak|akota)?\b\.?/i, 'N.D.' ).gsub(/\b(?:U\.?S\.?-)?(?:O(?:hio)|oiho)\b\.?/i, 'Ohio' ).gsub(/\b(?:U\.?S\.?-)?(?:Ok(?:la)?(?:homa)?|okalahoma)\b\.?/i, 'Okla.' ).gsub(/\b(?:U\.?S\.?-)?(?:Or(?:e|eg)?(?:on)?|orgon)\b\.?/i, 'Ore.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:PA|Penna?)(?:sylvania)?|pensylvania)\b\.?/i, 'Pa.' ).gsub(/\b(?:U\.?S\.?-)?(?:R(?:hode\s+)\.?\s*I(?:sland)?|rh?oa?de?\sisland)\b\.?/i, 'R.I.' ).gsub(/\b(?:U\.?S\.?-)?S(?:outh\s+)?\.?\s*C(?:ar)?(?:olin?a?)?\b\.?/i, 'S.C.' ).gsub(/\b(?:U\.?S\.?-)?S(?:o\s*|outh\s+)?\.?\s*D(?:ak|akota)?\b\.?/i, 'S.D.' ).gsub(/\b(?:U\.?S\.?-)?(?:Tn|Tenn)(?:i?e?ss?ee?)?\b\.?/i, 'Tenn.' ).gsub(/\b(?:U\.?S\.?-)?(?:Te?x)(a?e?i?s)?\b\.?/i, 'Texas' ).gsub(/\b(?:U\.?S\.?-)?Ut(?:ah|es|ar)?\b\.?/i, 'Utah' ).gsub(/\b(?:U\.?S\.?-)?V(?:ermon)?t\b\.?/i, 'Vt.' ).gsub(/\b(?:U\.?S\.?-)?(?:Wash|Wa|Wn)(?:ington)?\b\.?/i, 'Wash.' ).gsub(/\b(?:U\.?S\.?-)?W(?:est\s+)?\.?\s*V(?:irg|a)?(?:i?ni?a)?\b\.?/i, 'W.Va.' ).gsub(/\b(?:U\.?S\.?-)?V(?:irg|a)(?:i?ni?a)?\b\.?/i, 'Va.' ).gsub(/\b(?:U\.?S\.?-)?(?:(?:Wis?c?(?:onsin)?)|wisconson)\b\.?/i, 'Wis.' ).gsub(/\b(?:U\.?S\.?-)?(?:Wyo?(?:ming)?|wh?y?i?oming)\b\.?/i, 'Wyo.' )
    stateout = state
    $states_to_postal.each do |key, value|
      unless state == nil
        state = state.gsub(/#{key}(?! #{$street_types_regex})(?!,? #{$states_to_AP_regex})/, value)
      end

    end
    state = state.gsub(/(^\s*|\s*$)/, '')
    return state
  end

  def Address.address_division(address)
    split_address = address.split(', ')
    street_number = split_address[0]
    suite = nil
    suite = split_address[1] unless split_address[1] == nil
    return street_number, suite
  end

  def Address.split_address(address)
    address, suite = Address.address_division(address)
    street_number = /^\d+/.match(address).to_s
    address_mod = (address.class == String ? address.gsub(/^\d+ /, '') : '')
    compass_point = /^(n\b\.?|s\b\.?|e\b\.?|w\b\.?|n\.? ?e\b\.?|n\.? ?w\b\.?|s\.? ?e\b\.?|s\.? ?w\b\.?)/i.match(address_mod).to_s
    address_mod = address_mod.gsub(/^(n\b\.?|s\b\.?|e\b\.?|w\b\.?|n\.? ?e\b\.?|n\.? ?w\b\.?|s\.? ?e\b\.?|s\.? ?w\b\.?) /i, '')
    street_name = address_mod
    # street_name = nil
    # street_type = nil
    # $street_types_array.each do |street_reg|
    # 	street_type = street_reg.match(address_mod).to_s
    # 	street_name = address_mod.gsub(street_reg, '')
    # end
    return street_number, compass_point, street_name, suite
  end

end
