# frozen_string_literal: true

module MiniLokiC
  module Population
    module Publications
      # connection to production PL database and
      # generation output to console
      class Base
        def initialize
          pl_user = MiniLokiC.read_ini['pl_user']

          @route = MiniLokiC::Connect::Mysql.on(
            PL_PROD_DB_HOST, 'jnswire_prod',
            pl_user['user'], pl_user['password']
          )
        end

        private

        def get(query)
          publications = @route.query(query).to_a

          if publications.any?
            puts "--\n\n"
            puts 'organization id:    ' + @org_id.to_s.green
            puts 'organization name:  ' + publications.first['org_name'].green
            puts "\npublication(s):"

            publications.each do |p|
              puts "  #{p['name']}".green
              p.delete('org_name')
            end

            puts "\n--\n"
          end

          @route&.close
          publications
        end
      end
    end
  end
end
