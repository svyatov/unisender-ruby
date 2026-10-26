# frozen_string_literal: true

module Unisender
  # Observes the complete named response decode inside each request attempt.
  class Client
    def request(method, params: {})
      perform_request(method, params, named: false) # : Response[json]
    end

    private

    # rubocop:disable-next Metrics/MethodLength -- One attempt owns request construction, decoding, and error context.
    def perform_request(method, params, named:)
      uri, headers, body = request_values(method, params)
      attempt = 0
      with_retries(method) do
        attempt += 1
        exchange(method, uri, headers:, body:, attempt:,
                              input_count: named ? Acceptance.input_count(method, params) : nil) do |http|
          decode_response(http, method, params, named)
        end
      end
    rescue Error, ValidationError => e
      raise e.with_operation(method), cause: nil
    end

    def with_retries(method, &)
      # rubocop:disable-next Style/ClassEqualityComparison -- Preserve custom subclass types in Steep's fallback.
      if @retry_policy.class == RetryPolicy
        @retry_policy.call(method, execution: @execution, &)
      else
        @retry_policy.call(method, &)
      end
    end

    def request_values(method, params)
      validate_request(method, params)
      uri = URI("https://api.unisender.com/#{@language}/api/#{method}")
      headers = { "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8", "User-Agent" => USER_AGENT }
      body = Form.encode(params.merge("api_key" => @api_key, "format" => "json"))
      [uri, headers, body]
    end

    def decode_response(http, method, params, named)
      response = Protocol.parse(http, method:)
      return response unless named

      result = bind_task(method, Results.build(method, response), params)
      observe_acceptance(method, Acceptance.input_count(method, params), result, nil)
      result
    end

    # rubocop:disable-next Metrics/MethodLength, Metrics/ParameterLists -- Keep attempt metadata with its exchange.
    def exchange(operation, uri, headers:, body:, attempt: 1, input_count: nil)
      check_execution!
      acquire_limit(operation)
      check_execution!
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = nil
      begin
        response = post_request(uri, headers, body)
        result = yield response
      rescue StandardError => e
        e.with_http(status: response&.status, request_id: response&.headers&.[]("x-request-id")) if e.is_a?(Error)
        observe_acceptance(operation, input_count, nil, e)
        observe(operation, attempt, started, response, e)
        raise
      end
      observe(operation, attempt, started, response, nil)
      result
    end

    def acquire_limit(operation)
      limiter = operation == "track_events" ? @configuration.event_rate_limiter : @configuration.rate_limiter
      return unless limiter

      # rubocop:disable-next Style/ClassEqualityComparison -- Preserve custom subclass types in Steep's fallback.
      if limiter.class == RateLimiter
        limiter.acquire(operation, execution: @execution)
      else
        limiter.acquire(operation)
      end
    end

    def post_request(uri, headers, body)
      transport = @transport
      case transport
      when Transport
        if [Transport, PersistentTransport].include?(transport.class)
          return transport.post(uri, headers:, body:, execution: @execution)
        end
      end
      transport.post(uri, headers:, body:)
    end

    def observe(operation, attempt, started, response, error)
      event = Observation.event(operation, attempt, started, response, error)
      Observation.emit(@configuration.instrumentation, event)
    end

    def validate_request(method, params)
      raise ArgumentError, "Invalid API method name" unless method.match?(%r{\A(?:async/)?[A-Za-z][A-Za-z0-9]*\z})
      return unless params.keys.any? { |key| RESERVED_PARAMETERS.include?(key.to_s) }

      raise ArgumentError, "api_key and format are managed by the client"
    end
  end
end
