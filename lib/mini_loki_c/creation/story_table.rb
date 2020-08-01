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

      def to_html_with_style
        style + to_html
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

      def style
        '<style>table.hle {
          width: 100%;
          margin: 0 1em 1em 0;
          font-size: .8em;
          height: auto;
          font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
            font-size: 100%;
          font: inherit;
        }
        table.hle thead {
          border-bottom: 2px solid #000;
          font-size: .8em;
          font-weight: 700;
          vertical-align: bottom;
          text-transform: uppercase
        }
        table.hle th {
          font-weight: 400;
          text-align: left;
          padding: .5em .5em .2em;
          line-height: 1.4em;
          vertical-align: bottom;
        }
        table.hle td {
          border-bottom: 1px solid #cdcdcd;
          text-align: left;
          vertical-align: middle;
          line-height: 1.35em;
          padding: .25em .5em;
          height: 100%
        }
        table.hle tr.last td {
          border-bottom: 1px solid #222222;
        }
        table.hle tr.footer td {
          font-weight: 700;
            box-sizing: border-box;
          font-smoothing: antialiased;
          background-color: #f0f0f0;
          text-rendering: optimizeLegibility
        }
        @media only screen and (max-width:1024px) {
          table.hle td,
          table.hle th {
            font-size: 95%!important
          }
        }
        @media only screen and (max-width:960px) {
          table.hle td,
          table.hle th {
            font-size: 90%!important
          }
        }
        @media only screen and (max-width:924px) {
          table.hle td,
          table.hle th {
            font-size: 85%!important
          }
        }
        @media only screen and (max-width:894px) {
          table.hle td,
          table.hle th {
            font-size: 80%!important
          }
        }
        @media only screen and (max-width:860px) {
          table.hle td,
          table.hle th {
            font-size: 75%!important
          }
        }
        @media only screen and (max-width:450px) {
          table.hle td,
          table.hle th {
            font-size: 70%!important
          }
        }
        @media only screen and (max-width:400px) {
          table.hle td,
          table.hle th {
            font-size: 65%!important
          }
        }
        @media only screen and (max-width:370px) {
          table.hle td,
          table.hle th {
            font-size: 60%!important
          }
        }</style>'
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
