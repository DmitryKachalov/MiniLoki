# frozen_string_literal: true

module Pipeline
  module Endpoint
    # Job endpoints
    module Job
      # https://pipeline-api-docs.locallabs.com/#create-a-job
      def post_job(options = {})
        post('jobs', options)
      end
    end
  end
end
