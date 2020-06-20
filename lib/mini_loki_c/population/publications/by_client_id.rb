# frozen_string_literal: true

require_relative 'by_client_id/query.rb'

module MiniLokiC
  module Population
    module Publications
      # get publications by client id
      class ByClientId < Publications::Base
        def initialize(org_id, client_ids = [])
          super()
          @client_ids = client_ids.join(',')
          @org_id = org_id
        end
      end
    end
  end
end
