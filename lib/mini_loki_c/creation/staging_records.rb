# frozen_string_literal: true

module MiniLokiC
  module Creation
    class StagingRecords # :nodoc:
      def self.[](staging_table, options)
        new(staging_table, options)
      end

      def each
        raise ArgumentError, 'No block is given' unless block_given?

        rows.each { |row| yield(row) }
      end

      private

      def initialize(staging_table, options)
        @staging_table = staging_table
        @options = options
      end

      def rows
        query = "SELECT * FROM `#{@staging_table}` "\
                "#{@options['where'] ? "WHERE #{@options['where']}" : ''}"\
                "#{@options['limit'] ? "LIMIT #{@options['limit'].to_i}" : ''}"

        conn = Connect::Mysql.on(DB01, 'lokic')
        result = conn.query(query)
        conn.close

        result
      end
    end
  end
end
