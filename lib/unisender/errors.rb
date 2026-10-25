# frozen_string_literal: true

module Unisender
  # Base class for client and service failures.
  class Error < StandardError
    def inspect
      "#<#{self.class}>"
    end
  end

  # Main API failure, including failures returned with HTTP 200.
  class APIError < Error
    attr_reader :response, :code, :details

    def initialize(response)
      @response = response
      @code = response.data["code"]
      @details = response.data["error"]
      super("UniSender rejected the API request")
    end
  end

  # Non-success HTTP response, including redirects.
  class HTTPError < Error
    attr_reader :response

    def initialize(response)
      @response = response
      super("UniSender returned an unsuccessful HTTP status")
    end
  end

  class InvalidResponseError < Error; end

  # Network or TLS failure with no complete HTTP response.
  class TransportError < Error
    def initialize(message, retryable: false)
      @retryable = retryable
      super(message)
    end

    def retryable?
      @retryable
    end
  end

  class TimeoutError < TransportError; end

  # A failed event request can still have accepted some events (HTTP 400).
  class EventError < HTTPError
    def code
      response.data["code"]
    end

    def details
      response.data.fetch("details", response.data["error"])
    end

    def possibly_partially_accepted?
      response.status == 400
    end
  end

  # Carries the completed batches and the range whose outcome needs inspection.
  class BatchError < Error
    attr_reader :completed_responses, :failed_range, :error

    def initialize(completed_responses:, failed_range:, error:)
      @completed_responses = completed_responses.dup.freeze
      @failed_range = failed_range.freeze
      @error = error
      super("UniSender batch failed; inspect the completed responses and failed range")
    end
  end

  class PaginationError < Error; end

  # The API accepted the import request but rejected some records.
  class PartialFailure < Error
    attr_reader :response

    def initialize(response)
      @response = response
      super("UniSender rejected part of the batch")
    end
  end

  # Includes the last response for an unexpected or failed asynchronous task state.
  class TaskError < Error
    attr_reader :response

    def initialize(response)
      @response = response
      super("UniSender task returned an unexpected state")
    end
  end
end
