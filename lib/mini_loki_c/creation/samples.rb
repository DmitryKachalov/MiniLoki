# frozen_string_literal: true

require 'fileutils'

module MiniLokiC
  module Creation
    class Samples # :nodoc:
      def initialize(staging_table, options = {})
        @options = options
        @staging_table = staging_table
        @path = "hle/samples/s#{options['story_type']}"

        FileUtils.mkpath(@path)
      end

      def insert(sample)
        sample[:body].gsub!(/(?:^|\n\n|\n\t)(.+)(?:\n\n*|\n\t|$)/, '<p>\1</p>')
        file = "#{@path}/staging_row_#{sample[:staging_row_id]}.html"
        File.open(file, 'wb') { |f| f.write(basic_html_substitutions_body(sample)) }

        puts "file://#{File.expand_path(file)}".green
      end

      private

      def basic_html_substitutions_body(sample)
        "<html>
          <head>
            <title>
              #{sample[:staging_row_id]}
            </title>
            <style>
              #{TABLE_STYLES}
            </style>
          </head>"\
          "<body style='margin: 0 25% 0 25%;'>"\
            "<h1>#{sample[:headline]}</h1>"\
            "<h4>#{sample[:teaser]}</h4>"\
            "#{sample[:body]}"\
          '</body>'\
        '</html>'
      end

      TABLE_STYLES =
        %|table.hle {
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
          }|
    end
  end
end
