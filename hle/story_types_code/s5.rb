# frozen_string_literal: true

class S5
  include MiniLokiC::Connect
  include MiniLokiC::Population
  include MiniLokiC::Creation

  STAGING_TABLE = 's5_staging'

  # eg. school_year: 2018-19
  def population(options)
    db01 = Mysql.on(DB01, 'usa_raw')
    db02 = Mysql.on(DB02, 'loki_storycreator')


    publications = [
        Publications.by_org_client_id(org_id, [120]),
        Publications.mm_excluding_states(org_id, ['California'])
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
