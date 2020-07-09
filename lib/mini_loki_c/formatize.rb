# frozen_string_literal: true

require_relative 'formatize/numbers'
require_relative 'formatize/money'
require_relative 'formatize/address'

module MiniLokiC
  module Formatize
    include Money
    include Numbers
  end
end