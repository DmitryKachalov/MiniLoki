# frozen_string_literal: true

class S18
  include MiniLokiC::Connect
  include MiniLokiC::Population
  include MiniLokiC::Creation

  STAGING_TABLE = 's18_staging'

  def plural(noun, count)
    count == 1 ? noun : "#{noun}s"
  end

  def ranking(rows, rank_by, desc = true)
    rows.sort_by! {|r| (desc ? -1 : 1) * r[rank_by].to_i}
    rank = 0
    prev = -1
    rows.each_with_index do |row, i|
      if row[rank_by].round != prev
        prev = row[rank_by].round
        rank = i + 1
      end
      row['rank'] = rank
    end
  end

  def median(array)
    return nil if array.empty?

    sorted = array.sort
    len = sorted.length
    (sorted[(len-1)/2] + sorted[len/2])/2.0
  end

  def month_name(num)
    months =['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
    months[num-1]
  end


  def committees_query(m, y)
    %(select t1.formatted_name as committee_name, t1.registered_entity_id, t1.pl_production_org_id, t2.month_amount
      from (select formatted_name, registered_entity_id, pl_production_org_id from minnesota_campaign_finance_committees state = 'MN') t1
   join (select site_source_committee_id, sum(cash_amount) as month_amount from minnesota_campaign_finance_contribution
   where cash_amount > 0 and year(received_date) = '#{y}' and month(received_date) = '#{m}' group by site_source_committee_id) t2
   on t1.registered_entity_id = t2.site_source_committee_id
   order by month_amount desc
   limit 50;)
  end

  #def committees_contributions_query(m, y, id)
  #  %(select cash_amount as contribution_amount from minnesota_campaign_finance_contribution where year(received_date) = #{y}
  #                                     and month(received_date) = #{m} and cash_amount > 0 and registered_entity_id = #{id};)
  #end


  # def story_type_table(raw_committees, yr, mn)
  # raw_committees.each do |row|
  # id = row['registered_entity_id']
  #   committees_contributions = committees_contributions_query(mn, yr, id)
  #
  #   [
  #       row['rank'],
  #       row['committee_name'],
  #       Formatize::Money.add_commas(row['month_amount'],
  #                                   median)
  #   ]
  # end





  #  commitees = raw_committees.map do |row|
  #   [
  #       row['rank'],
  #        row['committee_name'],
  #        Formatize::Money.add_commas(row['month_amount'],
  #                                    median)
  #    ]
  #  end

  # StoryTable.new(header: %w[Rank District Salary], content: commitees).to_json
  #end


  def population(options)
    db01 = Mysql.on(DB01, 'usa_raw')
    db02 = Mysql.on(DB02, 'loki_storycreator')


    year = options['year']
    month = options['month']
    time_frame = "m:#{month}:#{year}"


    comms = committees_query(month, year)
    committees = db01.query(comms).to_a
    ranked = ranking(committees, 'month_amount')
    #story_type_table(ranked)

    scrape_date = db01.query("select max(last_scrape_date) as scrape_date from from minnesota_campaign_finance_contribution;").to_a[0]['scrape_date'].to_s

    table = StoryTable.new
    table.header = "Rank, Committee, Amount, Median contribution amount".split(', ')
    table.content = []

    ranked.each do |row|
      break if table.content.size >= 50

      committee_contributions = db01.query("select cash_amount as contribution_amount from minnesota_campaign_finance_contribution where year(received_date) = #{year}
                                       and month(received_date) = #{month} and cash_amount > 0 and registered_entity_id = '#{row['registered_entity_id']}';").to_a.map{|i| i['contribution_amount']}

      median_contribution = median(committee_contributions)

      table.content << [row['rank'], row['committee_name'], Formatize::Money.add_commas(row['month_amount']), Formatize::Money.add_commas(median_contribution)]
    end

    committees_num = table.content.size

    committees.each do |committee|

      org_id = committee['pl_production_org_id']

    publications = [
        Publications.by_org_client_id(org_id, [120]),
        Publications.by_org_client_id(org_id, [91]),
        Publications.mm_excluding_states(org_id, ['Minnesota'])
    ]

    publications.flatten.uniq.each do |publication|
      raw = {}
      raw['client_id'] = publication['client_id']
      raw['client_name'] = publication['client_name']
      raw['publication_id'] = publication['id']
      raw['publication_name'] = publication['name']
      raw['organization_ids'] = org_id

      raw['time_frame'] = time_frame
      raw['committees_num'] = committees_num
      raw['year'] = year
      raw['month'] = month
      raw['scrape_date'] = scrape_date
      raw['table_data'] = table.to_json

      staging_insert_query = SQL.insert_on_duplicate_key(STAGING_TABLE, raw)
      db02.query(staging_insert_query)
    end
      end

    db01.close
    db02.close
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

      sample[:headline] = ''
      sample[:teaser] = ''
      sample[:body] = ''

      samples.insert(sample)
    end
  end
end

