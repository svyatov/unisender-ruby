# frozen_string_literal: true

module Unisender
  # Metadata deliberately excludes request bodies, headers, and response payloads.
  RequestEvent = Data.define(:operation, :attempt, :duration, :http_status, :outcome, :error_category, :request_id)

  # Callback failures cannot change the outcome of an API request.
  module Observation
    def self.emit(callback, event)
      return unless callback

      callback.call(event)
    rescue StandardError
      nil
    end

    def self.event(operation, attempt, started, response, error)
      RequestEvent.new(operation: Error.safe_operation(operation) || "request", attempt:,
                       duration: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started,
                       http_status: response&.status, outcome: error ? :failure : :success,
                       error_category: category(error), request_id: response&.headers&.[]("x-request-id"))
    end

    def self.category(error)
      return nil unless error

      error.is_a?(Error) ? error.category : :unexpected
    end
  end
end
