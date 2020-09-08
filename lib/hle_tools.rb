# frozen_string_literal: true

module HleTools
  def self.call(options)
    tool = options.delete('tool').split('::')
    require_relative "../hle/scripts/#{tool[0]}/#{tool[1]}.rb"

    execute(options)
  end
end
