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

        Mysql2::Client.new(
          host: host, database: database,
          username: username, password: password,
          connect_timeout: 180, reconnect: true, encoding: 'utf8'
        )
      end
    end
  end
end
