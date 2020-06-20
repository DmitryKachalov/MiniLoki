# frozen_string_literal: true

module MiniLokiC
  module Population
    module SQL
      module_function

      def insert_on_duplicate_key(table, options = {})
        keys = options.keys.map { |k| "`#{k}`" }.join(', ')
        values = options.values.map { |v| v.nil? ? 'null' : v.to_s.to_json }.join(', ')
        updates = options.map { |(k, v)| "`#{k}` = #{v.nil? ? 'null' : v.to_s.to_json}" }.join(', ')

        "insert into `#{table}` (#{keys}) values (#{values}) "\
        "on duplicate key update #{updates}"
      end
    end
  end
end
