# frozen_string_literal: true

module MiniLokiC
  module Creation
    class Samples # :nodoc:
      def initialize(staging_table, options = {})
        @staging_table = staging_table
        @path = "hle/samples/#{@staging_table}"
        @options = options

        FileUtils.mkpath(@path)
      end

      def insert(sample)
        file = "#{@path}/#{sample[:staging_row_id]}.html"
        File.open(file, 'wb') { |f| f.write(basic_html_substitutions_body(sample)) }
        puts "file://#{File.expand_path(file)}".green
      end

      private

      def basic_html_substitutions_body(sample)
        output = sample[:body].gsub(/(?:^|\n\n|\n\t)(.+)(?:\n\n*|\n\t|$)/, '<p>\1</p>')
        '<html><head><title></title><style></style></head>'\
          "<body style='width: 50%;'>"\
            "<h1>#{sample[:headline]}</h1>"\
            "<h4>#{sample[:teaser]}</h4>"\
            "#{output}"\
          '</body>'\
        '</html>'
      end
    end
  end
end
