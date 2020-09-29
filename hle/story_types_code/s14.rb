# frozen_string_literal: true

class S14
  include MiniLokiC::Connect
  include MiniLokiC::Population
  include MiniLokiC::Creation

  STAGING_TABLE = 'quarterly_other_tax_by_state_staging'

  def normalize_to_positive(value)
    value.negative? ? value * -1 : value
  end

  def number_to_money(value, rounding = 2, currency = '$')
    prefix = value.to_f.negative? ? "-#{currency}" : currency.to_s
    parts = normalize_to_positive(value).to_f.round(rounding).to_s.split('.')
    parts.delete_at(1) if parts[1].to_i.zero?
    counter = 2
    parts[0] = parts[0].split('').reverse.each_with_index.map do |el, i|
      counter += 1
      (counter % 3).zero? && !i.zero? ? el += ',' : el
    end.reverse.join('')
    "#{prefix}#{parts.join('.')}"
  end

  def number_to_money_suffixed(value, suffix = '')
    if value >= 10**9
      value = (value.to_f / (10**9)).round(1)
      suffix = ' quadrillion' if suffix.eql?('')
    elsif value >= 10**6
      value = (value.to_f / (10**6)).round(1)
      suffix = ' trillion' if suffix.eql?('')
    elsif value >= 10**3
      value = (value.to_f / (10**3)).round(1)
      suffix = ' billion' if suffix.eql?('')
    elsif value > 0
      value = value.to_f.round(1)
      suffix = ' million' if suffix.eql?('')
    else
      return ''
    end
    "#{number_to_money(value, 1)}#{suffix}"
  end

  def table_query(info)
    %(select SUM(IF(dt_code = 'T01', val, null)) `Property Taxes`,
           SUM(IF(dt_code in('T09','T13','T10','T15','T12','T16','T14','T11','T19'), val, null)) `Sales and Gross Receipts Taxes`,
           SUM(IF(dt_code in('T40','T41'), val, null)) `Income Taxes`,
           SUM(IF(dt_code in('T20','T27','T24','T25','T22','T23','T21','T28','T29'), val, null)) `License Taxes`,
           SUM(IF(dt_code in('T50','T53','T51','T99'), val, null)) `Other Taxes`
    from quarterly_summary_of_state_and_local_taxes_data t1
      join quarterly_summary_of_state_and_local_taxes_geo_levels t2
        on t1.geo_idx = t2.geo_idx
      join quarterly_summary_of_state_and_local_taxes_time_periods t3
        on t1.per_idx = t3.per_idx
      join quarterly_summary_of_state_and_local_taxes_data_types as t4
        on t1.dt_idx = t4.dt_idx
    where per_name = #{info['period'].dump} and
          cat_idx = 3 and
          geo_desc = #{info['state'].dump};)
  end

  def last_quarter_query
    %(select per.per_name q
    from quarterly_summary_of_state_and_local_taxes_data root
      join quarterly_summary_of_state_and_local_taxes_time_periods per
          on per.id = root.per_idx
      join quarterly_summary_of_state_and_local_taxes_data_types dt
          on dt.id = root.dt_idx
    where dt.dt_code in ('T50', 'T53', 'T51', 'T99') and
        root.cat_idx = 3 and
        root.report_date = (select max(report_date) from quarterly_summary_of_state_and_local_taxes_data)
    order by per.id desc
    limit 1;)
  end

  def states_query
    %(select geo_desc name,
           geo_code st_abbr
    from quarterly_summary_of_state_and_local_taxes_geo_levels
    where geo_desc != 'U.S. Total';)
  end

  def org_ids_query
    %(select name,
           short_name st_abbr,
           pl_production_org_id
    from usa_administrative_division_states;)
  end

  def another_get_pubs_method(state)
    "SELECT c.id AS id, c.name AS publication_name, cc.id AS client_id, cc.name AS client_name
      FROM client_companies AS cc
      JOIN communities AS c ON c.client_company_id = cc.id
      WHERE c.client_company_id in (select id from client_companies where name = 'MM - #{state}' ) and c.id not in (
          select pg.project_id
          from project_geographies pg
          join communities c on c.id = pg.project_id and pg.geography_type = 'State'
          join client_companies cc on cc.id = c.client_company_id and cc.name rlike 'MM - '
        )
        and c.id not in (2041, 2419, 2394)
    ORDER BY c.name;"
  end

  def quarter_state_tax_query(quarter, state)
    %(select geo.geo_desc state,
           per.per_name period,
           sum(root.val) tax
    from quarterly_summary_of_state_and_local_taxes_data root
        join quarterly_summary_of_state_and_local_taxes_time_periods per
            on per.id = root.per_idx
        join quarterly_summary_of_state_and_local_taxes_categories cat
            on cat.id = root.cat_idx
        join quarterly_summary_of_state_and_local_taxes_data_types dt
            on dt.id = root.dt_idx
        join quarterly_summary_of_state_and_local_taxes_geo_levels geo
            on geo.id = root.geo_idx
    where per.per_name = #{quarter.dump} and
          dt.dt_code in ('T50', 'T53', 'T51', 'T99') and
          root.cat_idx = 3 and
          geo.geo_code != 'US' and
          geo.geo_desc = #{state.dump} and
          root.report_date = (select max(report_date) from quarterly_summary_of_state_and_local_taxes_data)
    group by geo_desc, per_name
    order by geo_desc;)
  end

  def story_table(raw)
    table = StoryTable.new(header: ['Type of Tax', 'Amount (in millions of dollars)'], content: [])

    raw.each do |key, value|
      next if value.nil?

      table.content << [
        key,
        value.negative? ? '$0' : number_to_money(value)
      ]
    end

    table.to_json
  end

  def population(options)
    loki_db = Mysql.on(DB02, 'loki_storycreator')
    db01 = Mysql.on(DB01, 'usa_raw')
    db13 = Mysql.on(DB13, 'usa_raw')

    last_available_quarter = db13.query(last_quarter_query).first['q']
    states = db13.query(states_query).to_a
    pl_org_ids = db01.query(org_ids_query).to_a

    states.each do |state|
      pl_org_id = pl_org_ids.find { |st| st['st_abbr'] == state['st_abbr'] }['pl_production_org_id']
      info = db13.query(quarter_state_tax_query(last_available_quarter, state['name'])).first
      next if info['tax'] < 1

      raw_table = db13.query(table_query(info)).first
      table = story_table(raw_table)

      period = info['period']
      time_frame = "q:#{period[1]}:#{period[2..-1]}"

      ['Metro Business', 'Metric Media'].each do |client|
        publications = if client.eql?('Metro Business')
                         Publications.by_org_client_id(pl_org_id, [120])
                       else
                         Publications.mm_by_state(info['state'])
                       end

        publications.each do |publication|
          next if publication['name'].empty?

          hash = {}
          hash['publication_id'] = publication['id']
          hash['publication_name'] = publication['name']
          hash['client_id'] = publication['client_id']
          hash['client_name'] = publication['client_name']
          hash['organization_ids'] = pl_org_id
          hash['time_frame'] = time_frame
          hash['period'] = period
          hash['state'] = info['state']
          hash['tax'] = info['tax']
          hash['story_table'] = table

          query = SQL.insert_on_duplicate_key(STAGING_TABLE, hash)
          loki_db.query(query)
        end
      end
    end

    loki_db.close
    db01.close
    db13.close

    PopulationSuccess[STAGING_TABLE] unless ENV['RAILS_ENV']
  end

  def normalize_state_headline(name)
    if name.eql?('District of Columbia')
      'D.C.'
    elsif name.eql?('New York')
      'New York state'
    elsif name.eql?('Washington')
      'The state of Washington'
    else
      name
    end
  end

  def normalize_d_of_c_body(name)
    name.eql?('District of Columbia') ? 'The District of Columbia' : name
  end

  def quarter_body(q)
    {
      'Q1' => '1st',
      'Q2' => '2nd',
      'Q3' => '3rd',
      'Q4' => '4th'
    }[q]
  end

  def creation(options)
    samples = Samples.new(STAGING_TABLE, options)

    StagingRecords[STAGING_TABLE, options].each do |stage|
      sample = {}
      sample[:staging_row_id] = stage['id']
      sample[:publication_id] = stage['publication_id']
      sample[:organization_ids] = stage['organization_ids']
      sample[:time_frame] = stage['time_frame']

      quarter = stage['period'][0..1]
      year = stage['period'][2..5]
      state = stage['state']
      tax = stage['tax']
      table = StoryTable.new.from_json(stage['story_table']).to_html

      sample[:headline] = %(#{normalize_state_headline(state)} reports #{number_to_money_suffixed(tax)} in miscellaneous tax revenues in #{quarter} #{year})
      sample[:teaser] = %(#{normalize_d_of_c_body(state)} collected #{number_to_money_suffixed(tax)} in miscellaneous tax revenue during the )
      sample[:teaser] += %(#{quarter_body(quarter)} quarter of #{year}, according to the )

      output = sample[:teaser]
      output += "U.S. Census Bureau's Quarterly Summary of State and Local Taxes".to_link(
        'https://www.census.gov/programs-surveys/qtax.html'
      ) + ".\n"
      output += %(In addition to detailed tax revenue data from each state, the Quarterly Summary of State and Local )
      output += %(Government Tax Revenue includes an estimate of state and local government tax revenue at a national level.\n)
      output += %(The Census Bureau cautions that it sets the tax classifications among the survey categories, and they )
      output += %(may differ from the classifications set by the state governments.\n)
      output += %(<strong style='font-size: 18px'>#{quarter_body(quarter)} Quarter #{state} Tax Collections</strong>)
      output += table
      output += %(<small>Source: U.S. Census Bureau</small>)

      sample[:teaser] += "U.S. Census Bureau's Quarterly Summary of State and Local Taxes."
      sample[:body] = output

      samples.insert(sample)
    end
  end
end
