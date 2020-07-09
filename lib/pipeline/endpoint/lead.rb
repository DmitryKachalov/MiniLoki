# frozen_string_literal: true

module Pipeline
  module Endpoint
    # Lead endpoints
    module Lead
      # https://pipeline-api-docs.locallabs.com/#get-a-lead
      def get_lead(id)
        get("leads/#{id}", {})
      end

      # https://pipeline-api-docs.locallabs.com/#create-a-lead
      def post_lead(options = {})
        post('leads', options)
      end

      # https://pipeline-api-docs.locallabs.com/#update-a-lead
      def update_lead(id, options = {})
        put("leads/#{id}", options)
      end

      # https://pipeline-api-docs.locallabs.com/#delete-a-lead
      def delete_lead(id)
        delete("leads/#{id}", {})
      end
    end
  end
end
