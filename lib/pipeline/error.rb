# frozen_string_literal: true

module Pipeline
  # Custom error class for rescuing
  # from all pipeline-api errors
  class PipelineError < StandardError; end

  # raised when passed wrong environment name
  # instead of staging or production
  class EnvironmentError < PipelineError
    def message
      'You can pass only :staging or :production'
    end
  end

  # raised when _safe mode catch three exceptions
  class SafeMethodError < PipelineError; end
end
