# frozen_string_literal: true

module Unisender
  # Stable categories and safe recovery hints supplement the upstream details.
  class Error
    HINTS = {
      authentication: "Check the API key.", authorization: "Check API access and account permissions.",
      invalid_argument: "Check the operation parameters.", payment: "Check the account balance.",
      rate_limit: "Wait before another request; check whether repeating this operation is safe.",
      not_found: "Check the requested identifier.", client_closed: "Create an open client before making a request.",
      pagination_limit: "Resume from next_offset with an explicit page budget.",
      task_failed: "Inspect the task response before starting another task.",
      task_state: "Inspect the task response and documented states.",
      unknown_task_state: "Inspect the task response and update the supported task states.",
      partial_failure: "Reconcile accepted records before retrying rejected records.",
      download: "Inspect the download reason and discard or retain partial output explicitly."
    }.freeze
    def self.safe_operation(operation)
      OPERATIONS.include?(operation) ? operation.dup.freeze : nil
    end

    def category
      error = self # : Error
      case error
      when APIError then api_category(error.code)
      when HTTPError then http_category(error.response.http_status)
      when InvalidResponseError then :invalid_response
      when TimeoutError then :timeout
      when TransportError then :transport
      else :unknown
      end
    end

    def transient?
      error = self # : Error
      case error
      when APIError then RetryPolicy::TRANSIENT_CODES.include?(error.code)
      when HTTPError then [429, 502, 503, 504].include?(error.response.http_status)
      when TimeoutError then true
      when TransportError then error.retryable?
      else false
      end
    end

    def safe_to_retry?
      name = operation
      name.is_a?(String) && RetryPolicy::READ_ONLY.include?(name) && transient?
    end

    def request_id
      response = diagnostic_response
      @context_request_id || response&.headers&.[]("x-request-id")
    end

    def recovery_hint
      HINTS.fetch(category, "Inspect the failure and reconcile mutations before repeating the operation.")
    end

    private

    def api_category(code)
      case code
      when "invalid_api_key" then :authentication
      when "access_denied" then :authorization
      when "invalid_arg" then :invalid_argument
      when "not_enough_money" then :payment
      when "retry_later" then :transient
      when "api_call_limit_exceeded_for_api_key", "api_call_limit_exceeded_for_ip" then :rate_limit
      else :unknown
      end
    end

    def http_category(status)
      case status
      when 401 then :authentication
      when 403 then :authorization
      when 429 then :rate_limit
      when 500..599 then :service_unavailable
      else :http
      end
    end
  end
end
