# frozen_string_literal: true
# Creator: Artem Yarockiy a.k.a. Art Jarocki
# Story type: #16/897 Campaign Finance Donations - Missouri - Committee contributions weekly
# Created: October 2020
# branch: art_jarocki_stories

class S16
  include MiniLokiC::Connect
  include MiniLokiC::Population
  include MiniLokiC::Formatize
  include MiniLokiC::Creation
  
  STAGING_TABLE = 's16_staging'
  
  def population(options)
    week    = Date.today.cweek
    @year   = week == 1 ? Date.today.year - 1 : Date.today.year
    week    = week == 1 ? 52 : week - 1
    @mode   = options['fill'].nil? ? "= #{week}" : "<= #{week}"
    source_query
    
    @source.each do |week, committees|
      committees.each do |committee, data|
        publications = [
          Publications.by_org_client_id(data[:org_id], [120]),
          Publications.mm_excluding_states(data[:org_id], ['Missouri'])]
        type         =
          case committee
          when /\bpac\b/i; ', a political action committee, '
          when /\b(friends of|vote for)\b/i; ', a campaign committee, '
          else ''
          end
        
        publications.flatten.each do |pub|
          host = Mysql.on(DB02, 'loki_storycreator')
          h    = {}
          
          h['organization_ids'] = data[:org_id]
          h['publication_id']   = pub['id'].to_i
          h['publication_name'] = pub['publication_name']
          h['client_id']        = pub['client_id']
          h['client_name']      = pub['client_name']
          h['date']             = week
          h['committee']        = committee
          h['type']             = type
          h['amount']           = data[:amount]
          h['table']            = data[:table].to_json
          h['time_frame']       = Frame[:weekly, data[:date].to_s]
          
          host.query(SQL.insert_on_duplicate_key(STAGING_TABLE, h))
          host.close
        end
      end
    end
    
    nolog { PopulationSuccess[STAGING_TABLE] }
  end
  
  def creation
    samples = Samples.new(STAGING_TABLE, options)
  
    StagingRecords[STAGING_TABLE, options].each do |stage|
      sample = {}
      sample[:staging_row_id]   = stage['id']
      sample[:publication_id]   = stage['publication_id']
      sample[:organization_ids] = stage['organization_ids']
      sample[:time_frame]       = stage['time_frame']

      date      = Date.parse(stage[:date.to_s]).strftime("%B %-d")
      committee = stage[:committee.to_s]
      amount    = stage[:amount.to_s]
      type      = stage[:type.to_s]
      table     = StoryTable(stage['table'])
      url       = 'https://mec.mo.gov/'

      sample[:headline] = "Who contributed to #{committee} during week ending #{date}".squeeze(' ')
      sample[:teaser]   = "#{committee}#{type} received #{amount} during the week ending #{date}.".squeeze(' ')
      sample[:body]     = <<~BODY.squeeze(' ').chomp
        #{committee}#{type} received #{amount} during the week ending #{date}.
        Here are the 100 largest contributions that #{committee} received during the week ending #{date}, according to \
        the #{'Missouri Ethic Commission'.to_link(url)}.
        #{table}
      BODY

      samples.insert(sample)
    end
  end
  
  private
  
  def source_query
    host  = Mysql.on(DB01, 'usa_raw')
    query = <<~SQL
      SELECT
        WEEK(contribution_date) AS week
      , committee_name_cleaned AS committee
      , contribution_date AS date
      , TRIM(CONCAT(conf.name_cleaned, ' ', conl.name_cleaned)) AS contributor
      , ROUND(contribution_amount) AS amount
      , pl_production_org_id AS org_id
      FROM usa_raw.campaign_finance_missouri_contributions_202005 AS main
        JOIN usa_raw.campaign_finance_missouri_committees_202005 AS comm
          ON main.mecid = comm.mecid
        JOIN usa_raw.campaign_finance_missouri_contributor__cleaned_last_names AS conl
          ON contributor_last_name = conl.name
        JOIN usa_raw.campaign_finance_missouri_contributor__cleaned_first_names AS conf
          ON contributor_first_name = conf.name
      WHERE YEAR(contribution_date) = #{@year}
        AND WEEK(contribution_date) #{@mode}
        AND committee_type IN ('Campaign', 'Candidate', 'Political Action', 'Political Party')
        AND pl_production_org_id IS NOT NULL
      ORDER BY week, committee_name, contribution_date, conf.name_cleaned, conl.name_cleaned;
    SQL
    source_raw = host.query(query, symbolize_keys: true).to_a
    host.close
    
    @source = {}
    source_raw.each do |el|
      weekend                                     = Date.strptime("#{Date.today.year} #{el[:week]} 6", '%Y %U %w').to_s
      @source[weekend]                          ||= {}
      @source[weekend][el[:committee]]          ||= {}
      @source[weekend][el[:committee]][:date]     = el[:date]
      @source[weekend][el[:committee]][:amount] ||= 0
      @source[weekend][el[:committee]][:amount]  += el[:amount]
      @source[weekend][el[:committee]][:org_id] ||= ''
      @source[weekend][el[:committee]][:org_id]   = el[:org_id]
      @source[weekend][el[:committee]][:table]  ||= StoryTable.new(header: %w[Date Contributor Amount], content: [])
      @source[weekend][el[:committee]][:table].content << [el[:date].to_s, el[:contributor].squeeze(' '), "$#{Numbers.add_commas(el[:amount])}"]
    end
  end
end
