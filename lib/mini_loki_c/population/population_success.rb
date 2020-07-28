# frozen_string_literal: true

module MiniLokiC
  module Population
    module PopulationSuccess
      def self.[](staging_table)
        query = "SELECT MAX(iter_id) id FROM `#{staging_table}`;"
        iter = Connect::Mysql.exec_query(DB02, 'loki_storycreator', query).first
        return if iter['id'].nil?

        query = "UPDATE iterations SET population = TRUE WHERE id = #{iter['id']};"
        Connect::Mysql.exec_query(DB02, 'lokic', query)
      end
    end
  end
end
