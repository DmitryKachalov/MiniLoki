# frozen_string_literal: true

require_relative 'configuration.rb'
require_relative 'connection.rb'
require_relative 'request.rb'
require_relative 'endpoint.rb'

module Pipeline
  # Class for api requests to PL
  class Client
    include Connection
    include Request
    include Endpoint

    attr_reader :environment
    attr_accessor :token, :endpoint

    def initialize(environment)
      raise EnvironmentError unless %i[staging production].include?(environment)

      @environment = environment
      Pipeline.options(environment).each { |name, value| send("#{name}=", value) }
    end

    private

    def method_missing(symbol, *args)
      method = symbol.to_s
      super unless method.end_with?('_safe')

      method.delete_suffix!('_safe')
      sleep = 1

      begin
        send(method, *args)
      rescue Faraday::Error => e
        raise e if sleep > 127

        sleep(sleep)
        sleep *= 2
        retry
      end
    end

    def respond_to_missing?(*several_variants)
      several_variants.all? { |v| v.to_s.end_with?('_safe') } || super
    end
  end
end
