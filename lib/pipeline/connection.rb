# frozen_string_literal: true

require 'faraday'

module Pipeline
  # initialize faraday connection
  module Connection
    private

    def connection
      options = {
        url: endpoint,
        headers: {
          'Authorization' => token,
          'Content-Type' => 'application/json',
          'X-Force-Update' => 'true'
        }
      }

      Faraday::Connection.new(options)
    end
  end
end
