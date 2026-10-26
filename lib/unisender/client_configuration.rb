# frozen_string_literal: true

module Unisender
  # Explicit construction, immutable configuration variants, and lifetime.
  class Client
    class << self
      def open(api_key:, **)
        raise ArgumentError, "Client.open requires a block" unless block_given?

        client = new(api_key:, **)
        begin
          yield client
        ensure
          client.close
        end
      end

      # rubocop:disable-next Metrics/ParameterLists -- Mirrors the constructor options for typed forwarding.
      def from_env(env: ENV, language: :en, transport: nil, retry_policy: nil, open_timeout: nil,
                   read_timeout: nil, write_timeout: nil, max_retries: nil, max_elapsed: nil,
                   message_defaults: {}, instrumentation: nil, persistent: false, rate_limiter: nil)
        key = env["UNISENDER_API_KEY"]
        raise ArgumentError, "UNISENDER_API_KEY is required" unless key

        new(api_key: key, language:, transport:, retry_policy:, open_timeout:, read_timeout:, write_timeout:,
            max_retries:, max_elapsed:, message_defaults:, instrumentation:, persistent:, rate_limiter:)
      end
    end

    # @type method with: (**config_value) -> Client
    def with(**options)
      settings = @configuration.options_for(options)
      key = settings.delete(:api_key)
      case key
      when String then Client.new(api_key: key, **settings)
      else raise ArgumentError, "api_key must be a string"
      end
    end

    def close
      @configuration.close
    end
  end
end
