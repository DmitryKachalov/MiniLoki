# frozen_string_literal: true

require_relative 'metric_media/query.rb'

module MiniLokiC
  module Population
    module Publications
      class MetricMedia < Publications::Base
        # org_id [int]    -- pipeline_organization_id.
        # states [string] -- this parameter is optional. If you need to limit the list of states, please pass the states
        #                    you are interested in, separated by commas e.g.: 'Michigan,Iowa,North Carolina'
        def initialize(org_id, states = [])
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

        private

        def mm_ids(states)
          ids_states = @route.query(ids_query).to_a

          if states.any?
            ids_states = ids_states.keep_if do |row|
              states.include?(row['state'])
            end
          end

          ids_states.map { |row| row['client_id'] }.join(',')
        end
      end
    end
  end
end
