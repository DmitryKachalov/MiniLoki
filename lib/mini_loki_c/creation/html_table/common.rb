# frozen_string_literal: true

module MiniLokiC
  module Creation
    class HtmlTable
      module Common
        def common
          '<div style="display:table; border-style: solid; border-width: 1px;">'\
          "#{header}"\
          "#{body}"\
        '</div>'
        end

        def header
          raw_table_header = @table.first.keys.map { |key| to_table_cell(key, true) }
          to_table_row(raw_table_header)
        end

        def body
          raw_table_body = @table.map do |row|
            raw_table_row = row.values.map { |value| to_table_cell(value) }
            to_table_row(raw_table_row)
          end

          raw_table_body.join
        end

        def to_table_cell(value, header = false)
          cell = "<div style=\"padding: 10px;#{header ? ' text-align: center;' : ''}\">"\
                 "#{value}"\
               '</div>'

          '<div style="display:table-cell; border-style: solid; border-width: 1px;">'\
          "#{header ? "<b>#{cell}</b>" : cell}"\
        '</div>'
        end

        def to_table_row(row)
          '<div style="display:table-row; border-style: solid; border-width: 1px;">'\
          "#{row.join}"\
        '</div>'
        end
      end
    end
  end
end
