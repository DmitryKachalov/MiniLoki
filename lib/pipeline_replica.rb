# frozen_string_literal: true

require_relative 'mini_loki_c/connect/mysql.rb'
require_relative 'pipeline_replica/client.rb'

# Make sql-requests to PL staging/production replica
module PipelineReplica
  include MiniLokiC::Connect

  def self.[](environment)
    PipelineReplica::Client.new(environment.to_sym)
  end
end
