# frozen_string_literal: true

module MiniLokiC
  module Population
    module Publications
      # Queries for getting MM publications
      class MetricMedia < Publications::Base
        private

        def ids_query
          %|select id client_id,
                   replace(name, 'MM - ', '') state
            from client_companies
            where name like 'MM -%';|
        end

        def pubs_query
          %|select o.name org_name,
                   c.id,
                   c.name,
                   cc.id client_id,
                   cc.name client_name
            from organizations o
              left join organization_communities oc
                on oc.organization_id = o.id
              left join communities c
                on c.id = oc.community_id
              left join client_companies cc
                on cc.id = c.client_company_id
            where organization_id = #{@org_id} and
                  c.client_company_id in (#{@client_ids})
            group by c.id;|
        end

        def pubs_excluding_states_query
          %|select o.name org_name,
                   c.id,
                   c.name,
                   cc.id client_id,
                   cc.name client_name
            from organizations o
                left join organization_communities oc
                    on oc.organization_id = o.id
                left join communities c
                    on c.id = oc.community_id
                left join client_companies cc
                    on c.client_company_id = cc.id
            where c.client_company_id in (#{@client_ids}) and
                  c.id not in (
                    select pg.project_id
                    from project_geographies pg
                        join communities c
                            on c.id = pg.project_id and
                               pg.geography_type = 'State'
                        join client_companies cc on
                            cc.id = c.client_company_id and
                            cc.name rlike 'MM - ') and
                  c.id not in (2041, 2419, 2394) and
                  organization_id = #{@org_id}
            group by c.id;|
        end

        def pubs_only_states_query
          %|select o.name org_name,
                   c.id,
                   c.name,
                   cc.id client_id,
                   cc.name client_name
            from organizations o
                left join organization_communities oc
                    on oc.organization_id = o.id
                left join communities c
                    on c.id = oc.community_id
                left join client_companies cc
                    on c.client_company_id = cc.id
            where c.client_company_id in (#{@client_ids}) and
                  (c.id in (
                    select pg.project_id
                    from project_geographies pg
                        join communities c
                            on c.id = pg.project_id and
                               pg.geography_type = 'State'
                        join client_companies cc on
                            cc.id = c.client_company_id and
                            cc.name rlike 'MM - ') or
                  c.id in (2041, 2419, 2394)) and
                  organization_id = #{@org_id}
            group by c.id;|
        end
      end
    end
  end
end
