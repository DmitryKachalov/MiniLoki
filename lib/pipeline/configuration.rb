# frozen_string_literal: true

require_relative '../mini_loki_c'

module Pipeline
  # Define constants and methods
  # related to pipeline-api configuration
  module Configuration

    # # @return hash of options for pl access
    def options(environment)
      {
        token: MiniLokiC::Configuration.read_ini["pipeline-#{environment}-loki-user"]['token'],
        endpoint: MiniLokiC::Configuration.read_ini["pipeline-#{environment}-loki-user"]['endpoint']
      }
    end
  end
end
