# frozen_string_literal: true

require_relative 'html_table/common.rb'

module MiniLokiC
  module Creation
    # class for build a table for the story body
    class HtmlTable
      include Common

      def self.common(array_json)
        new(array_json).send(:common)
      end

      private

      def initialize(array_json)
        @table = array_json.is_a?(String) ? JSON.parse(array_json) : array_json
      end
    end
  end
end
