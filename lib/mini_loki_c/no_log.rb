# frozen_string_literal: true

module MiniLokiC
  module NoLog
    module_function

    def nolog
      return if ENV['RAIlS_ENV']

      yield if block_given?
    end
  end
end
