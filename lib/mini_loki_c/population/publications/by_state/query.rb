# frozen_string_literal: true

module MiniLokiC
  module Population
    module Publications
      # Queries for getting publications by state
      class ByState < Publications::Base
        private

        def pubs_query
          %(select c.id as id,
                   c.name as publication_name,
                   cc.id as client_id,
                   cc.name as client_name
            from client_companies as cc
                   join communities as c on c.client_company_id = cc.id
            where c.client_company_id in (select id from client_companies where name = 'MM - #{@state}' ) and c.id not in (
                             select pg.project_id
                             from project_geographies pg
                                    join communities c on c.id = pg.project_id and pg.geography_type = 'State'
                                    join client_companies cc on cc.id = c.client_company_id and cc.name = 'MM - #{@state}'
                             )
            and c.id not in (2041, 2419, 2394);)
        end
      end
    end
  end
end
