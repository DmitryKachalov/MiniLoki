# frozen_string_literal: true

module MiniLokiC
  module Creation
    # class for build a table for the story body
    class StoryTable
      attr_accessor :header, :content, :footer
      attr_reader :options

      def initialize(header: nil, content: nil, footer: nil)
        @header = header
        @content = content
        @footer = footer
        @options = {}.with_indifferent_access
      end

      def to_json(*_args)
        check
        { header: unquote(@header), content: unquote(@content), footer: unquote(@footer), options: @options }.to_json
      end

      def from_json(json)
        raw = JSON.parse(json).with_indifferent_access
        @header = quote(raw['header'])
        @content = quote(raw['content'])
        @footer = quote(raw['footer'])
        @options = raw['options'] || {}.with_indifferent_access
        check
        self
      end

      def to_html
        hidden_ids = []
        header = ''
        @header.each_with_index do |col, i|
          if @options[:hide_columns]&.include?(col)
            hidden_ids << i
          else
            header << "<th>#{col}</th>"
          end
        end
        header_html = "<thead><tr>#{header}</tr></thead>"

        row_count = @content.count

        rows_to_mark = {}
        @options[:markers]&.each do |marker|
          find_rows(marker[:conditions], true).each do |idx|
            rows_to_mark[idx] = {} if rows_to_mark[idx].nil?
            if marker[:column].nil?
              rows_to_mark[idx][:row] = marker[:color]
            else
              rows_to_mark[idx][:cell] = {} if rows_to_mark[idx][:cell].nil?
              rows_to_mark[idx][:cell][@header.index(marker[:column])] = marker[:color]
            end
          end
        end
        content_html = ''
        @content.each_with_index do |r, i|
          content_html << "<tr#{i == row_count - 1 ? ' class="last"' : ''}#{rows_to_mark[i] && rows_to_mark[i][:row] ? " style='background-color: #{rows_to_mark[i][:row]};'" : ''}>"
          if r.all? { |v| v.to_s.empty? }
            content_html << "<td colspan=#{r.count}>&hellip;</td>"
          else
            r.each_with_index do |col, j|
              next if hidden_ids.include?(j)

              content_html << '<td'
              if rows_to_mark[i] && rows_to_mark[i][:cell] && rows_to_mark[i][:cell][j]
                content_html << " style='background-color: #{rows_to_mark[i][:row] ? rows_to_mark[i][:cell][j].to_s + 'a0' : rows_to_mark[i][:cell][j]};'"
              end
              content_html << ">#{col}</td>"
            end
          end

          content_html << '</tr>'
        end

        footer_html = ''
        unless @footer.nil?
          footer_html = '<tr class="footer">' + @footer.map.with_index { |col, i| hidden_ids.include?(i) ? '' : "<td>#{col}</td>" }.join + '</tr>'
        end

        '<table class="hle">' + header_html + '<tbody>' + content_html + footer_html + '</tbody></table>'
      end

      # conditions should be a hash with column name(s) as key(s) and value(s) from a row which need to be marked as value(s)
      # if soft = true it won't raise exception if can't find any row by conditions in the table (use it when a table is about "top N ...")
      def mark_row(conditions = nil, color: '#ffffb9', soft: false )
        find_rows(conditions, soft)
        @options[:markers] = [] unless @options[:markers]
        h = { conditions: conditions, color: color }.with_indifferent_access
        @options[:markers] << h unless @options[:markers].include?(h)
        self
      end

      # it similar to mark_row, but allows to mark a cell instead of whole row
      def mark_cell(conditions = nil, column = nil, color: '#99ccff', soft: false )
        raise 'Column name required!' if column.nil?
        raise "Wrong column name '#{column}'!" unless @header.include?(column)

        find_rows(conditions, soft)
        @options[:markers] = [] unless @options[:markers]
        h = { conditions: conditions, color: color, column: column }.with_indifferent_access
        @options[:markers] << h unless @options[:markers].include?(h)
        self
      end

      # clear all marks
      def unmark_everything
        @options.delete(:markers)
        self
      end

      # use it when you need to mark rows by a column, but you don't need this column
      def hide_column(name)
        raise "Wrong column name '#{name}'!" unless @header.include?(name)

        @options[:hide_columns] = [] unless @options[:hide_columns]
        @options[:hide_columns] << name.to_s
      end

      # after compression (if it makes sense) rows number will be base_row_count * 4 + 3
      def compress!(conditions = nil, base_row_count = 3)
        raise 'This table was already compressed!' if @options[:compressed]
        unless base_row_count && base_row_count == base_row_count.to_i && base_row_count > 2
          raise 'Base row count should be an integer greater than 2!'
        end

        if compression_makes_sense?(base_row_count)
          p 'will compress!'
          indexes = find_rows(conditions, false)
          raise 'Conditions should point exactly one row!' unless indexes.count == 1

          do_compress(base_row_count, indexes[0])
        end
        self
      end

      # it compresses table's copy
      def compress(conditions = nil, base_row_count = 3)
        dup.compress!(conditions, base_row_count)
      end

      def dup
        StoryTable.new.from_json(to_json)
      end

      def ranking!(arg = -1, rank_key: 'Rank', asc: false)
        raise "Ranking can't be used on compressed table!" if @options[:compressed]

        return self if @content.empty?

        clmn_numb =
          case arg
          when Integer; arg
          when String; @header.index(arg)
          else; nil
          end

        return self if clmn_numb.nil?

        begin
          @content.sort_by! { |row| (asc ? 1 : -1) * row[clmn_numb] }
        rescue TypeError
          # p "Attention! comparing non-digit values!"
          @content.sort_by! { |row| row[clmn_numb] }
          @content.reverse! unless asc
        end

        curr_value = @content.first[clmn_numb]
        curr_rank = 1
        free_numb = @content.first.size

        @content.map.with_index(1) do |row, index|
          unless row[clmn_numb].eql?(curr_value)
            curr_value = row[clmn_numb]
            curr_rank = index
          end

          row[free_numb] = curr_rank
          row.unshift(row.pop)
        end

        @header.unshift(rank_key)

        self
      end

      def delete_empty_columns!(empty_value = '')
        empty_cols = []
        (0..@header.count-1).each do |col_num|
          empty_cols << col_num if @content.all? { |r| r[col_num] == empty_value }
        end

        empty_cols.reverse.each do |col_num|
          @content.each do |arr|
            arr.delete_at(col_num)
          end
          @header.delete_at(col_num)
          @footer&.delete_at(col_num)
        end
        self
      end

      def empty?
        @content.empty?
      end

      def self.json_to_html(json)
        StoryTable.new.from_json(json).to_html
      end

      module ::Kernel
        private

        def StoryTable(json)
          StoryTable.json_to_html(json)
        end
      end

      private

      def compression_makes_sense?(base_row_count)
        (base_row_count * 4 + 3) * 2 < @content.count
      end

      def do_compress(base_row_count, index)
        new_content = []
        if index <= base_row_count * 2
          new_content += @content[0..base_row_count * 3]
          new_content << empty_row
          new_content += @content[- base_row_count - 1..-1]
        elsif index >= @content.count - base_row_count * 2
          new_content += @content[0..base_row_count]
          new_content << empty_row
          new_content += @content[- base_row_count * 3 - 1..-1]
        else
          new_content += @content[0..base_row_count - 1]
          new_content << empty_row
          new_content += @content[index - base_row_count..index + base_row_count]
          new_content << empty_row
          new_content += @content[- base_row_count..-1]
        end
        @content = new_content
        @options[:compressed] = true
      end

      def empty_row
        @header.map { |c| '' }
      end

      def find_rows(conditions, soft)
        unless conditions&.is_a?(Hash) && conditions.count > 0
          raise 'Conditions should be a Hash with at least one pair key-value!'
        end

        selected_rows_indexes = (0..@content.count-1).to_a
        conditions.each do |condition|
          idx = @header.index(condition[0].to_s)
          raise "Wrong condition '#{Hash[*condition]}' - key was not found among column headers!" if idx.nil?

          selected_rows_indexes &= @content.each_index.select { |i| @content[i][idx].to_s == condition[1].to_s }
        end
        raise "Wrong conditions '#{conditions}' - there is no suitable rows!" if selected_rows_indexes.empty? && !soft

        selected_rows_indexes
      end

      def check
        raise 'Header should be an Array with at least one element!' unless @header.is_a?(Array) && @header.count > 0
        unless @content.is_a?(Array) && @content.count > 0 && @content[0].is_a?(Array) && @content[0].count > 0
          raise 'Content should be an Array of Arrays with at least one element in each!'
        end

        if @footer.nil?
          raise 'Column count should be the same in all parts of a table!' if @header.count != @content[0].count
        else
          raise 'Footer should be an Array with at least one element!' unless @footer.is_a?(Array) && @footer.count > 0
          if @header.count != @content[0].count || @header.count != @footer.count
            raise 'Column count should be the same in all parts of a table!'
          end
        end
      end

      def quote(arr)
        return nil if arr.nil?

        if !arr[0].is_a?(Array)
          arr.map { |v| v.to_s.gsub('%%%','"')}
        else
          arr.map { |v| quote(v) }
        end
      end

      def unquote(arr)
        return nil if arr.nil?

        if arr[0].is_a?(Array)
          arr.map { |v| unquote(v)}
        else
          arr.map { |v| v.to_s.gsub('"','%%%')}
        end
      end
    end
  end
end
