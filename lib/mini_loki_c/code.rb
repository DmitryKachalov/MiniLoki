# frozen_string_literal: true

module MiniLokiC
  # class allow execute ruby code and upload files to database
  class Code
    def self.execute(method, options)
      new(options['story_type'], method, options).send(:exec)
    end

    def self.upload(options)
      new(options['story_type']).send(:upload)
    end

    def self.download(options)
      new(options['story_type']).send(:download)
    end

    private

    def initialize(story_type_id, method = nil, options = {})
      @story_type_id = story_type_id
      @method = method
      @options = options
    end

    def exec
      load file
      story_type_class = Object.const_get("S#{@story_type_id}")

      story_type_class.include(
        MiniLokiC::Connect,
        MiniLokiC::Formatize,
        MiniLokiC::Population,
        MiniLokiC::Creation
      )

      story_type_class.new.send(@method, @options)
    end

    def upload
      File.open(file, 'rb') do |f|
        file = f.read.dump
        query = 'INSERT INTO hle_file_blobs (story_type_id, file_blob) '\
                "VALUES (#{@story_type_id}, #{file}) ON DUPLICATE KEY UPDATE file_blob = #{file};"
        Connect::Mysql.exec_query(DB02, 'loki_storycreator', query)
      end
    end

    def download
      query = "SELECT file_blob b FROM hle_file_blobs WHERE story_type_id = #{@story_type_id};"
      blob = Connect::Mysql.exec_query(DB02, 'loki_storycreator', query).first

      raise ArgumentError, 'File for this story type not found' unless blob && blob['b']

      File.open("hle/story_types_code/s#{@story_type_id}.rb", 'wb') { |f| f.write(blob['b']) }
    end

    def file
      Dir['hle/story_types_code/*'].find { |f| f[%r{hle/story_types_code/s#{@story_type_id}\.rb}] }
    end

    def options_to_hash(options)
      return {} if options.empty?

      options = options.split(',')
      options = options.map { |opt| opt.gsub(/[\s+,'"]/, '') }

      options.each_with_object({}) do |opt, hash|
        hash[opt.split(/[=>,:]/).first.to_s] = opt.split(/[=>,:]/).last
      end
    end
  end
end
