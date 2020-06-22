# frozen_string_literal: true

module MiniLokiC
  # class allow execute ruby code and upload files to database
  class Code
    def self.execute(method, options)
      new(options.delete('story_type'), method, options).send(:exec)
    end

    def self.upload(options)
      new(options.delete('story_type')).send(:upload)
    end

    def self.download(options)
      new(options.delete('story_type')).send(:download)
    end

    private

    def initialize(story_type_id, method = nil, options = {})
      @story_type_id = story_type_id
      @method = method
      @options = options
    end

    def exec
      load find_file
      Object.const_get("S#{@story_type_id}").new.send(@method, @options)
      return unless Object.const_defined?("S#{@story_type_id}")

      Object.send(:remove_const, "S#{@story_type_id}")
    end

    def upload
      File.open(find_file, 'rb') do |f|
        file = f.read.dump
        query = 'INSERT INTO hle_file_blobs (story_type_id, file_blob) '\
                "VALUES (#{@story_type_id}, #{file}) ON DUPLICATE KEY UPDATE file_blob = #{file};"
        execute_query(DB05, 'loki_storycreator', query)
      end
    end

    def download
      query = "SELECT file_blob b FROM hle_file_blobs WHERE story_type_id = #{@story_type_id};"
      blob = execute_query(DB05, 'loki_storycreator', query).first
      return unless blob && blob['b']

      File.open("hle/code/s#{@story_type_id}.rb", 'wb') { |f| f.write(blob['b']) }
    end

    def find_file
      Dir['hle/code/*'].find { |f| f[%r{hle/code/s#{@story_type_id}\.rb}] }
    end

    def options_to_hash(options)
      return {} if options.empty?

      options = options.split(',')
      options = options.map { |opt| opt.gsub(/[\s+,'"]/, '') }

      options.each_with_object({}) do |opt, hash|
        hash[opt.split(/[=>,:]/).first.to_s] = opt.split(/[=>,:]/).last
      end
    end

    def execute_query(host, database, query)
      conn = Connect::Mysql.on(host, database)
      query_result = conn.query(query)
      conn.close

      query_result
    end
  end
end
