# frozen_string_literal: true

module PipelineReplica
  module Request
    # request return job or nil
    module Organization
      def get_active_organization_ids(ids)
        stringify_ids = ids.join(',')
        org_ids_q = organizations_query(stringify_ids)
        @pl_replica.query(org_ids_q).to_a.map { |o| o['id'] }
      end

      private

      def organizations_query(ids)
        "SELECT id FROM organizations WHERE id IN (#{ids})"
      end
    end
  end
end
