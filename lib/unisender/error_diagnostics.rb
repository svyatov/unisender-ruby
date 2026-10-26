# frozen_string_literal: true

module Unisender
  # Stable categories and safe recovery hints supplement the upstream details.
  class Error
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
      error = self
      error.response.headers["x-request-id"] if error.is_a?(HTTPError) || error.is_a?(APIError)
    end

    def recovery_hint
      case category
      when :authentication then "Check the API key."
      when :authorization then "Check API access and account permissions."
      when :invalid_argument then "Check the operation parameters."
      when :payment then "Check the account balance."
      when :rate_limit then "Wait before another request; check whether repeating this operation is safe."
      else "Inspect the failure and reconcile mutations before repeating the operation."
      end
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
