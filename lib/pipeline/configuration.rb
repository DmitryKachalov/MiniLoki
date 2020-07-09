# frozen_string_literal: true

module Pipeline
  # Define constants and methods
  # related to pipeline-api configuration
  module Configuration

    # # @return hash of options for pl access
    def options(environment)
      token = MiniLokiC.read_ini["pipeline-#{environment}-loki-user"]['token']
      endpoint = MiniLokiC.read_ini["pipeline-#{environment}-loki-user"]['endpoint']

      { token: token, endpoint: endpoint }
    end
  end
end
