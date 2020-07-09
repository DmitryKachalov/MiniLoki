# frozen_string_literal: true

require_relative 'connection.rb'
require_relative 'request.rb'

module PipelineReplica
  class Client < Connection
    include Request

    def initialize(environment)
      raise ArgumentError unless %i[staging production].include?(environment)

      super
    end
  end
end
