# frozen_string_literal: true

module MiniLokiC
  module Population
    # module generate SQL queries
    module SQL
      module_function

      def insert_on_duplicate_key(table, options = {})
        keys = []
        values = []
        updates = []

        options.map do |(k, v)|
          key = "`#{k}`"
          value = v.nil? ? 'null' : v.to_s.to_json

          keys << key
          values << value
          updates << "#{key} = #{value}"
        end

        "INSERT INTO `#{table}` (#{keys.join(', ')}) "\
        "VALUES (#{values.join(', ')}) "\
        "ON DUPLICATE KEY UPDATE #{updates.join(', ')}"
      end
    end
  end
end
