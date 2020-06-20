# fronzen_string_literal: true

module MiniLokiC
  module Population
    module Publications
      # Queries for getting publications by client id
      class ByClientId < Publications::Base
        private

        def pubs_query
          %(select o.name org_name,
                   c.id,
                   cc.id client_id
            from organizations o
                left join organization_communities oc
                    on oc.organization_id = o.id
                left join communities c
                    on c.id = oc.community_id
                left join client_companies cc
                    on cc.id = c.client_company_id
            where organization_id = #{@org_id} #{@client_ids ? "and c.client_company_id in (#{@client_ids})" : ''}
            group by c.id;)
        end
      end
    end
  end
end
