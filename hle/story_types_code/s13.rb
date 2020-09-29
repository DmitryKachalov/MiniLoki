# frozen_string_literal: true

class S13
  include MiniLokiC::Connect
  include MiniLokiC::Population
  include MiniLokiC::Creation

  STAGING_TABLE = 'inventories_by_merchant_wholesalers_staging'

  def forbidden_pubs
    ['Yellowhammer Times', 'Natural State News', 'Grand Canyon Times', 'Last Frontier News', 'Golden State Today',
     'Centennial State News', 'Constitution State News', 'First State Times', 'Sunshine Sentinel', 'Sun Shine Sentinel',
     'Peach Tree Times', 'Aloha State News', 'Hawkeye Reporter', 'Gem State Wire', 'Hoosier State Today',
     'Sunflower State News', 'Bluegrass Times', 'Pelican State News', 'Bay State News', 'Maryland State Wire',
     'Great Lakes Wire', 'Minnesota State Wire', 'Show-Me State Times', 'Magnolia State News', 'Big Sky Times',
     'Old North News', 'Peace Garden News', 'Cornhusker State News', 'Granite State Times', 'Garden State Times',
     'Enchantment State News', 'Silver State Times', 'Empire State Today', 'Buckeye Reporter', 'Sooner State News',
     'Beaver State News', 'Keystone Today', 'Ocean State Today', 'Palmetto State News', 'Rushmore State News',
     'Volunteer State News', 'Lone Star Standard', 'Beehive State News', 'Old Dominion News', 'Green Mountain Times',
     'Evergreen Reporter', 'The Sconi', 'Mountain State Times', 'Equality State News', 'Pine State News'].map(&:upcase)
  end

  def pubs_query
    %(select c.id id,
           c.name name,
           cc.id client_id,
           cc.name client_name
    from jnswire_prod.client_companies cc
      join jnswire_prod.communities c
        on c.client_company_id = cc.id
     where c.client_company_id in (#{((153..200).to_a << 110 << 120).join(",")})
     order by c.name;)
  end

  def max_period_in_stage_query
    %|select date(str_to_date(concat('01', month, year), '%d%M%Y')) stage_max_period
    from inventories_by_merchant_wholesalers_staging
    where year = (select max(year) from inventories_by_merchant_wholesalers_staging);|
  end

  def max_report_date_query
    %|select max(report_date) date
    from usa_raw.mm_monthly_wholesale_trade_sales_and_inventories_data;|
  end

  def population(options)
    org_id = 644_640_085

    db13 = Mysql.on(DB13, 'usa_raw')
    loki_db = Mysql.on(DB02, 'loki_storycreator')
    pl_core = PipelineReplica[:production].pl_replica
    publications = pl_core.query(pubs_query).to_a

    publications = publications.reject { |e| forbidden_pubs.include?(e['name'].upcase) }
    stage_max_period = loki_db.query(max_period_in_stage_query).first['stage_max_period']
    max_report_date = db13.query(max_report_date_query).first['date']

    loop do
      stage_max_period = stage_max_period >> 1
      time_frame = "m:#{stage_max_period.month}:#{stage_max_period.year}"

      puts stage_max_period, stage_max_period.strftime('%b%Y') unless ENV['RAILS_ENV']

      period_data = db13.query(%(
        select val sum,
               clean_cat_desc category
        from mm_monthly_wholesale_trade_sales_and_inventories_data root
            join mm_monthly_wholesale_trade_sales_and_inventories_categories cat
                on cat.cat_idx = root.cat_idx
            join mm_monthly_wholesale_trade_sales_and_inventories_data_types dt
                on dt.dt_idx = root.dt_idx
            join mm_monthly_wholesale_trade_sales_and_inventories_time_periods per
                on per.per_idx = root.per_idx
            join mm_monthly_wholesale_trade_sales_and_inventories_geo_levels geo
                on geo.geo_idx = root.geo_idx
        where root.is_adj = 1 and
              dt.dt_code = 'IM' and
              per_name = '#{stage_max_period.strftime('%b%Y')}' and
              cat.cat_desc regexp '^....:' and
              root.report_date = '#{max_report_date}';)).to_a

      break if period_data.count.zero?

      period_data.each do |data|
        publications.each do |publication|
          next if publication['name'].empty?

          hash = {}
          hash['client_id'] = publication['client_id']
          hash['client_name'] = publication['client_name']
          hash['publication_id'] = publication['id']
          hash['publication_name'] = publication['name']
          hash['organization_ids'] = org_id
          hash['time_frame'] = time_frame

          hash['merchant_wholesaler'] = data['category']
          hash['month'] = stage_max_period.strftime('%B')
          hash['year'] = stage_max_period.strftime('%Y')
          hash['sum'] = data['sum'].to_i

          query = SQL.insert_on_duplicate_key(STAGING_TABLE, hash)
          loki_db.query(query)
        end
      end
    end

    db13.close
    loki_db.close
    pl_core.close
    PopulationSuccess[STAGING_TABLE] unless ENV['RAILS_ENV']
  end

  def creation(options)
    samples = Samples.new(STAGING_TABLE, options)

    StagingRecords[STAGING_TABLE, options].each do |stage|
      sample = {}
      sample[:staging_row_id] = stage['id']
      sample[:publication_id] = stage['publication_id']
      sample[:organization_ids] = stage['organization_ids']
      sample[:time_frame] = stage['time_frame']

      merchant_wholesaler = stage['merchant_wholesaler'].gsub(/^\d{4,}: /, '')
      month = stage['month']
      year = stage['year']
      sum = Formatize::Money.huge_money_to_text(stage['sum'] * 1_000_000)

      sample[:headline] = %(#{merchant_wholesaler.capitalize} wholesalers report #{sum} in #{month} inventories)
      sample[:teaser] = %(Inventories held by #{merchant_wholesaler} wholesalers in #{month} #{year} were valued ) +
                        %(at #{sum}, according to the )

      output = sample[:teaser] + 'U.S. Census Bureau'.to_link('https://www.census.gov/') + ".\n"
      output += %(The data is after adjustment for seasonal variations and trading day differences, but not for price changes.\n)
      output += %(The Census Bureau conducts a monthly wholesale trade survey in order to provide )
      output += %(an up-to-date indication of sales and inventory trends for U.S. merchant wholesalers, )
      output += %(excluding manufacturers' sales branches and offices.\n\n)
      output += %(The survey is considered to be a reliable measure of current economic activity.\n)
      output += %(Information requested in the survey includes monthly sales reports, )
      output += %(end-of-month inventories, number of establishments covered by the report, )
      output += %(and the ending date of the reporting period.)

      sample[:body] = output
      sample[:teaser] += 'U.S. Census Bureau.'

      samples.insert(sample)
    end
  end
end
