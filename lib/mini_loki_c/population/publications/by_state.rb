# frozen_string_literal: true

require_relative 'by_state/query'

module MiniLokiC
  module Population
    module Publications
      # get publications by state
      class ByState < Publications::Base
        def initialize(state)
          super()
          @state = state
        end

        def pubs
          @route.query(pubs_query).to_a
        end
      end
    end
  end
end
