# frozen_string_literal: true

require_relative 'publications/base.rb'
require_relative 'publications/by_org_client_id.rb'
require_relative 'publications/metric_media.rb'
require_relative 'publications/from_lat_lon.rb'

module MiniLokiC
  module Population
    module Publications
      module_function

      # The methods are returned an array of hashes like this:
      # [{"id"=>2072, "name"=>"Hawkeye Reporter", "client_id"=>158, "client_name"=>"MM - Iowa "}]
      def by_org_client_id(org_id, client_ids = [])
        ByOrgClientId.new(org_id, client_ids).pubs
      end

      def mm(org_id, states = [])
        MetricMedia.new(org_id: org_id, states: states).pubs
      end

      def mm_excluding_states(org_id, states = [])
        MetricMedia.new(org_id: org_id, states: states).pubs_excluding_states
      end

      def mm_only_states(org_id, states = [])
        MetricMedia.new(org_id: org_id, states: states).pubs_only_states
      end

      def mm_by_state(state)
        MetricMedia.new(states: [state]).pubs_by_passed_state
      end
    end
  end
end
