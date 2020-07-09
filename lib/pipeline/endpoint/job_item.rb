# frozen_string_literal: true

module Pipeline
  module Endpoint
    # Job item endpoints
    module JobItem
      # https://pipeline-api-docs.locallabs.com/#create-a-job-item
      def post_job_item(options = {})
        post('job_items', options)
      end
    end
  end
end
