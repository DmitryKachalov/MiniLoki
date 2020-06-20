# frozen_string_literal: true

require_relative 'publications/base.rb'
require_relative 'publications/by_client_id.rb'
require_relative 'publications/metric_media.rb'
require_relative 'publications/from_lat_lon.rb'

module MiniLokiC
  module Population
    module Publications
      module_function

      # The methods are returned an array of hashes like this:
      # [{"id"=>2072, "name"=>"Hawkeye Reporter", "client_id"=>158, "client_name"=>"MM - Iowa "}]
      def by_client_id(org_id, client_ids = [])
        ByClientId.new(org_id, client_ids).pubs
      end

      def mm(org_id, states = [])
        MetricMedia.new(org_id, states).pubs
      end

      def mm_excluding_states(org_id, states = [])
        MetricMedia.new(org_id, states).pubs_excluding_states
      end

      def mm_only_states(org_id, states = [])
        MetricMedia.new(org_id, states).pubs_only_states
      end
    end
  end
end
