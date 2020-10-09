# frozen_string_literal: true

require 'time'
require 'mysql2'
require 'json'
require 'colorize'
require 'slack-ruby-client'
require 'active_support/core_ext/time'
require 'active_support/core_ext/hash'

require_relative '../config/databases.rb'
require_relative 'mini_loki_c/connect/mysql.rb'
require_relative 'mini_loki_c/initialization.rb'
require_relative 'mini_loki_c/population.rb'
require_relative 'mini_loki_c/creation.rb'
require_relative 'mini_loki_c/code.rb'

require_relative 'pipeline.rb'
require_relative 'pipeline_replica.rb'
require_relative 'export_backdated_stories.rb'
require_relative 'hle_tools.rb'

# local version of LokiC for test
# population/creation code and
# upload/download it to/from DB.
module MiniLokiC
  extend Initialization

  def self.execute!
    options = derive_options({})

    if options['story_type']
      if options['population']
        MiniLokiC::Code.execute(:population, options)
      elsif options['creation']
        MiniLokiC::Code.execute(:creation, options)
      elsif options['upload']
        MiniLokiC::Code.upload(options)
      elsif options['download']
        MiniLokiC::Code.download(options)
      end
    elsif options['tool']
      HleTools.call(options)
    elsif options['export_backdated']
      ExportBackdatedStories.find_and_export!
    else
      raise ArgumentError,
            'Please pass me one of these arguments: '\
            'population creation upload download tool export_backdated'
    end
  end
end

Slack.configure do |config|
  config.token = MiniLokiC.read_ini['slack_app_token']['token']
end

if ARGV.any?
  MiniLokiC.execute!
else
  puts '[ Test mode ON ]'.green
end
