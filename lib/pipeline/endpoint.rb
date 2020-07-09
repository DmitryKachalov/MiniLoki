# frozen_string_literal: true

require_relative 'endpoint/job.rb'
require_relative 'endpoint/job_item.rb'
require_relative 'endpoint/lead.rb'
require_relative 'endpoint/story.rb'

module Pipeline
  # Base module for assembling endpoints
  module Endpoint
    include Job
    include JobItem
    include Lead
    include Story
  end
end
