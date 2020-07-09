# frozen_string_literal: true

module PipelineReplica
  module Request
    # request return job or nil
    module Sections
      def get_sections
        @pl_replica.query(get_sections_query).to_a
      end

      private

      def get_sections_query
        'SELECT id, name FROM story_sections;'
      end
    end
  end
end
