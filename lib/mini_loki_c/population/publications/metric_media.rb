# frozen_string_literal: true

require_relative 'metric_media/query.rb'

module MiniLokiC
  module Population
    module Publications
      class MetricMedia < Publications::Base
        # org_id [int]    -- pipeline_organization_id.
        # states [Array]  -- this parameter is optional. If you need to limit the list of states, please pass
        #                    the states you are interested. e.g.: ['Michigan', 'Iowa', 'North Carolina']
        def initialize(org_id: nil, states: nil)
          super()
          @client_ids = mm_ids(states)
          @org_id = org_id
        end

        def pubs
          get(pubs_query)
        end

        def pubs_excluding_states
          get(pubs_excluding_states_query)
        end

        def pubs_only_states
          get(pubs_only_states_query)
        end

        def pubs_by_passed_state
          get(pubs_by_passed_state_query)
        end

        private

        def mm_ids(states)
          mm_states = @route.query(ids_query).to_a
          mm_states = mm_states.keep_if { |row| states.include?(row['state']) } if states.any?
          ids = mm_states.map { |row| row['client_id'] }.join(',')

          ids.empty? ? '0' : ids
        end
      end
    end
  end
end
