# frozen_string_literal: true

require 'mysql2'
require 'json'
require 'colorize'

require_relative '../config/databases.rb'
require_relative 'mini_loki_c/connect/mysql.rb'
require_relative 'mini_loki_c/initialization.rb'
require_relative 'mini_loki_c/population.rb'
require_relative 'mini_loki_c/creation.rb'
require_relative 'mini_loki_c/code.rb'

require_relative 'pipeline.rb'
require_relative 'pipeline_replica.rb'

# local version of LokiC for test
# population/creation code and
# upload/download it to/from DB.
module MiniLokiC
  extend Initialization

  def self.execute!
    options = derive_options({})
    raise ArgumentError, "Please pass '--story_type' argument." unless options['story_type']


    puts options
    if options['population']
      MiniLokiC::Code.execute(:population, options)
    elsif options['creation']
      MiniLokiC::Code.execute(:creation, options)
    elsif options['upload']
      MiniLokiC::Code.upload(options)
    elsif options['download']
      MiniLokiC::Code.download(options)
    else
      raise ArgumentError
    end
  end
end

if ARGV.any?
  MiniLokiC.execute!
else
  puts '[ Test mode ON ]'.green
end
