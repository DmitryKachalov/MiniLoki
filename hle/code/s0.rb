# frozen_string_literal: true

class S0 # :nodoc:
  include MiniLokiC::Connect
  include MiniLokiC::Population
  include MiniLokiC::Creation

  STAGING_TABLE = 'PUT STAGING TABLE NAME HERE'

  def population(options)
    db01 = Mysql.on(DB01, 'usa_raw')
    db05 = Mysql.on(DB05, 'loki_storycreator')

    db05.query('select 1;')

    db01.close
    db05.close
  end

  def creation(options)
    samples = Samples.new(STAGING_TABLE, options)

    StagingRecords[STAGING_TABLE, options].each do |stage|
      sample = {}
      sample[:staging_row_id] = stage['id']
      sample[:publication_id] = stage['publication_id']
      sample[:organization_ids] = stage['organization_ids']
      sample[:time_frame] = stage['time_frame']

      sample[:headline] = 'HEADLINE'
      sample[:teaser] = 'TEASER'

      output = 'output'
      output += 'table'

      sample[:body] = output

      samples.insert(sample)
    end
  end
end
