# frozen_string_literal: true

require_relative 'by_org_client_id/query.rb'

module MiniLokiC
  module Population
    module Publications
      # get publications by client id
      class ByOrgClientId < Publications::Base
        def initialize(org_id, client_ids = [])
          super()
          @client_ids = client_ids.join(',')
          @org_id = org_id
        end
      end
    end
  end
end
