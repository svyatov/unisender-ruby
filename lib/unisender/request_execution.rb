# frozen_string_literal: true

module Unisender
  # Observes the complete named response decode inside each request attempt.
  class Client
    def request(method, params: {})
      perform_request(method, params, named: false) # : Response[json]
    end

    private

    def perform_request(method, params, named:)
      uri, headers, body = request_values(method, params)
      attempt = 0
      @retry_policy.call(method) do
        attempt += 1
        exchange(method, uri, headers:, body:, attempt:) do |http|
          decode_response(http, method, params, named)
        end
      end
    rescue Error, ValidationError => e
      raise e.with_operation(method), cause: nil
    end

    def request_values(method, params)
      validate_request(method, params)
      uri = URI("https://api.unisender.com/#{@language}/api/#{method}")
      headers = { "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8" }
      body = Form.encode(params.merge("api_key" => @api_key, "format" => "json"))
      [uri, headers, body]
    end

    def decode_response(http, method, params, named)
      response = Protocol.parse(http, method:)
      return response unless named

      bind_task(method, Results.build(method, response), params)
    end

    # rubocop:disable-next Metrics/MethodLength -- Start the clock outside request failure handling.
    def exchange(operation, uri, headers:, body:, attempt: 1)
      @configuration.check_open!
      limiter = @configuration.rate_limiter
      limiter.acquire(operation) if limiter && operation != "track_events"
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = nil
      begin
        response = @transport.post(uri, headers:, body:)
        result = yield response
      rescue StandardError => e
        observe(operation, attempt, started, response, e)
        raise
      end
      observe(operation, attempt, started, response, nil)
      result
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
