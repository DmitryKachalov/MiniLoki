# frozen_string_literal: true

module PipelineReplica
  module Request
    # request return job or nil
    module PhotoBuckets
      def get_photo_buckets
        @pl_replica.query(get_photo_buckets_query).to_a
      end

      private

      def get_photo_buckets_query
        'SELECT id, name, minimum_width, minimum_height, '\
        'aspect_ratio from buckets;'
      end
    end
  end
end
