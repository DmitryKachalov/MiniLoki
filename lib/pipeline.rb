# frozen_string_literal: true

require_relative 'pipeline/error.rb'
require_relative 'pipeline/configuration.rb'
require_relative 'pipeline/client.rb'

# pipeline-api library.
# It gives the HLE-developers team
# access to a Pipeline thought api
module Pipeline
  extend Configuration

  def self.[](environment)
    Pipeline::Client.new(environment.to_sym)
  end
end
