# frozen_string_literal: true

module MiniLokiC
  module Connect
    # establishing connect to Mysql database
    module Mysql
      def self.on(host, database, username = nil, password = nil)
        unless username && password
          user = MiniLokiC.read_old_db
          username = user[:username]
          password = user[:password]
        end
        fallen = 0

        begin
          Mysql2::Client.new(
            host: host, database: database,
            username: username, password: password,
            connect_timeout: 180, reconnect: true,
            encoding: 'utf8'
          )
        rescue Mysql2::Error => e
          raise Mysql2::Error, e if fallen > 3

          fallen += 1
          sleep(3)
          retry
        end
      end

      def self.exec_query(host, database, query)
        conn = on(host, database)
        query_result = conn.query(query)
        conn.close

        query_result
      end
    end
  end
end
