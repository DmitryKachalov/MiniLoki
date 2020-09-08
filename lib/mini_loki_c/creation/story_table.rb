# frozen_string_literal: true

module MiniLokiC
  module Creation
    # class for build a table for the story body
    class StoryTable
      attr_accessor :header, :content, :footer

      def initialize(header: nil, content: nil, footer: nil)
        @header = header
        @content = content
        @footer = footer
      end

      def to_json(*_args)
        check
        { header: unquote(@header), content: unquote(@content), footer: unquote(@footer) }.to_json
      end

      def from_json(json)
        raw = JSON.parse(json)
        @header = quote(raw['header'])
        @content = quote(raw['content'])
        @footer = quote(raw['footer'])
        check
        self
      end

      def to_html
        header =
          '<thead><tr>' + @header.map { |v| "<th>#{v}</th>" }.join + '</tr></thead>'

        row_count = @content.count
        content = ''
        @content.each_with_index do |r, i|
          content += "<tr#{i == row_count - 1 ? ' class="last"' : ''}>" + r.map { |v| "<td>#{v}</td>" }.join + '</tr>'
        end

        footer = @footer.nil? ? '' : '<tr class="footer">' + @footer.map { |v| "<td>#{v}</td>" }.join + '</tr>'

        '<table class="hle">' + header + '<tbody>' + content + footer + '</tbody></table>'
      end

      def ranking!(arg = -1, rank_key: 'Rank', asc: false)
        return self if @content.empty?

        clmn_numb =
          case arg
          when Integer then arg
          when String then @header.index(arg)
          end

        return self if clmn_numb.nil?

        begin
          @content.sort_by! { |row| (asc ? 1 : -1) * row[clmn_numb] }
        rescue TypeError
          p 'Attention! comparing non-digit values!'
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

      private

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
        return if arr.nil?

        if arr[0].is_a?(Array)
          arr.map { |v| quote(v) }
        else
          arr.map { |v| v.to_s.gsub('%%%', '"') }
        end
      end

      def unquote(arr)
        return if arr.nil?

        if arr[0].is_a?(Array)
          arr.map { |v| unquote(v) }
        else
          arr.map { |v| v.to_s.gsub('"', '%%%') }
        end
      end
    end
  end
end
