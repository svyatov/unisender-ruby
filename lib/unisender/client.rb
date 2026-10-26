# frozen_string_literal: true

module Unisender
  # Synchronous client for the documented UniSender API.
  class Client
    RESERVED_PARAMETERS = %w[api_key format].freeze

    def initialize(api_key:, transport: Transport.new, language: :en, retry_policy: RetryPolicy.new)
      unless api_key.is_a?(String) && !api_key.strip.empty? && !api_key.match?(/[\r\n]/)
        raise ArgumentError, "api_key must be a nonempty string without line breaks"
      end
      raise ArgumentError, "language must be en or ru" unless %w[en ru].include?(language.to_s)

      @api_key = api_key.dup.freeze
      @language = language.to_s.dup.freeze
      @transport = transport
      @retry_policy = retry_policy
      freeze
    end

    def request(method, params: {})
      validate_request(method, params)
      uri = URI("https://api.unisender.com/#{@language}/api/#{method}")
      headers = { "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8" }
      body = Form.encode(params.merge("api_key" => @api_key, "format" => "json"))
      @retry_policy.call(method) do
        response = @transport.post(uri, headers:, body:)
        Protocol.parse(response, method:)
      end
    rescue Error => e
      raise e.with_operation(method), cause: nil
    end

    def inspect
      "#<Unisender::Client>"
    end

    private

    def validate_request(method, params)
      raise ArgumentError, "Invalid API method name" unless method.match?(%r{\A(?:async/)?[A-Za-z][A-Za-z0-9]*\z})
      return unless params.keys.any? { |key| RESERVED_PARAMETERS.include?(key.to_s) }

      raise ArgumentError, "api_key and format are managed by the client"
    end

    # The wire response stays JSON; each named operation declares the documented result type.
    # @type method invoke: (String, params, ?required: Array[String], ?comma: Array[String]) -> Response
    def invoke(method, params, required: [], comma: [])
      Validation.required!(params, required)
      Validation.operation!(method, params)
      comma.each do |name|
        value = params[name.to_sym]
        params[name.to_sym] = Validation.comma_list(value) if value.is_a?(Array)
      end
      Results.build(method, request(method, params:))
    end
  end
end
