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

  def month_days(mon,yer)
    mdays = [nil,31,28,31,30,31,30,31,31,30,31,30,31]
    mdays[2] = 29 if Date.leap?(yer)
    mdays[mon]
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

  def story_type_table(raw_committees)
    districts = raw_districts.map do |row|
      [
          row['rank'],
          row['district'],
          Formatize::Money.add_commas(row['salary'])
      ]
    end

    StoryTable.new(header: %w[Rank District Salary], content: districts).to_json
  end


  def population(options)
    db01 = Mysql.on(DB01, 'usa_raw')
    db02 = Mysql.on(DB02, 'loki_storycreator')


    year = options['year']
    month = options['month']
    day = month_days(month,year)
    report_date = Date.new(year,month,day)


    def districts_salaries_query(school_year)
      %(select root.district_code,
             d_info.district,
             district_amount salary
      from ca_report_card_teacher_salaries root
          join ca_report_card_district_contact_info d_info
              on d_info.district_code = root.district_code
      where school_year = '#{school_year}' and
            category = 'Superintendent Salary' and
            district_amount is not null and
            district_amount != 0
      group by root.district_code;)
    end



    publications = [
        Publications.by_org_client_id(org_id, [120]),
        Publications.mm_excluding_states(org_id, ['Minnesota'])
    ]

    publications.flatten.uniq.each do |publication|
      raw = {}
      raw['client_id'] = publication['client_id']
      raw['client_name'] = publication['client_name']
      raw['publication_id'] = publication['id']
      raw['publication_name'] = publication['name']
      raw['organization_ids'] = org_ids

      raw['time_frame'] = ''

      staging_insert_query = SQL.insert_on_duplicate_key(STAGING_TABLE, raw)
      db02.query(staging_insert_query)
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

