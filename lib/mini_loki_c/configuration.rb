# frozen_string_literal: true

module MiniLokiC
  # methods for read .ini files and
  # derive options
  module Configuration
    module_function
    def read_old_db
      user = {}

      File.open("#{ENV['HOME']}/ini/old_db.ini", 'r') do |db_ini|
        on_flag = 0

        db_ini.each do |line|
          if line =~ /^\s*\[database\]\s*$/
            on_flag = 1
            next
          end
          next unless on_flag == 1

          if line =~ /^\s*user=/
            user[:username] = line.sub(/^\s*user=(.*)$/, '\1').chomp
          elsif line =~ /^\s*password=/
            user[:password] = line.sub(/^\s*password=(.*)$/, '\1').chomp
          end
          on_flag = 0 if line =~ /^\[/
        end
      end

      user
    end

    def query_pl(query_here)
      try_number = 0
      begin
        pl_user = read_ini['pl_user']
        client = Mysql.on(PL_PROD_DB_HOST, 'jnswire_prod', pl_user['user'], pl_user['password'])
        results = client.query(query_here)
        client.close
        results
      rescue => e
        if try_number < 5
          sleep 3**try_number
          try_number += 1
          retry
        else
          raise e
        end
      end
    end

    def read_ini
      ini = File.read("#{ENV['HOME']}/ini/environment.ini")
      narf = ini.gsub(/\n/, ';').split(/\[([^\[]+)\];/).delete_if{|m| m[/^\s*$/]}
      na = narf.reject{|m| m[/;/]}
      rf = narf.reject{|m| !m[/;/]}
      narfnarf = Hash[na.zip(rf)]
      narfx3 = Hash.new
      narfnarf.each do |k, v|
        v = v.sub(/;*$/, '')
        narfx3[k] = Hash.new
        v.split(/;/).each do |m|
          narfx3[k][m.sub(/(.*)=>?.*/, '\1').strip] = m.sub(/.*=>?(.*)/, '\1').strip
        end
      end
      narfx3
    end

    def derive_options(*inputs)
      options = inputs.first

      if inputs[1].is_a?(Array)
        inputs[1] = inputs[1].first.split(/\s(?=--)/)
        inputs[1].each do |line|
          line.match(/--([^=]+)(?:=(.*)|\s*$)/) do |m|
            options[m[1]] = m[2].nil? || (m[2] == '') ? 'enabled' : m[2]
          end
        end
      elsif inputs[1]
        puts 'error: non-array as second argument in options derivation'
      end

      ARGV.each do |line|
        line = line.gsub(/\n/, '\\n')
        line.match(/--([^=]+)(?:=(.*)|\s*$)/) do |m|
          options[m[1]] = m[2].nil? || (m[2] == '') ? 'enabled' : m[2]
        end
      end

      options['cl_args']&.split(/;/)&.each do |line|
        line.match(/--([^=]+)(?:=(.*)|\s*$)/) do |m|
          options[m[1]] = m[2].nil? || (m[2] == '') ? 'enabled' : m[2]
        end
      end
      options
    end
  end
end