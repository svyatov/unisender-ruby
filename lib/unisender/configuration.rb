# frozen_string_literal: true

module Unisender
  # Immutable options; injected transports remain owned by the caller.
  # rubocop:disable-next Metrics/ClassLength -- Owns the complete public configuration and resource lifetime.
  class Configuration
    DEFAULT_KEYS = %i[sender_name sender_email lang].freeze
    TIMEOUT_KEYS = %i[open_timeout read_timeout write_timeout persistent].freeze
    RETRY_KEYS = %i[max_retries max_elapsed].freeze
    attr_reader :api_key, :language, :transport, :retry_policy, :message_defaults, :instrumentation, :rate_limiter

    # rubocop:disable-next Metrics/ParameterLists -- Public configuration options are explicit keywords.
    def initialize(api_key:, language: :en, transport: nil, retry_policy: nil, open_timeout: nil,
                   read_timeout: nil, write_timeout: nil, max_retries: nil, max_elapsed: nil,
                   message_defaults: {}, instrumentation: nil, persistent: false, rate_limiter: nil)
      @api_key, @language = credentials(api_key, language)
      @message_defaults = defaults(message_defaults)
      @instrumentation = instrumentation
      @transport = build_transport(transport, open_timeout, read_timeout, write_timeout, persistent)
      @retry_policy = build_retry(retry_policy, max_retries, max_elapsed)
      initialize_resources(rate_limiter, transport)
      @options = { api_key: @api_key, language: @language, transport:, retry_policy:, open_timeout:,
                   read_timeout:, write_timeout:, max_retries:, max_elapsed:, message_defaults: @message_defaults,
                   instrumentation:, persistent:, rate_limiter: }.freeze
      freeze
    end

    def options_for(changes)
      options = @options.dup
      clear_alternative(options, changes, :transport, TIMEOUT_KEYS)
      clear_alternative(options, changes, :retry_policy, RETRY_KEYS)
      options.merge!(changes)
      merge_defaults(options, changes)
      options
    end

    def merge_defaults(options, changes)
      return unless changes.key?(:message_defaults)

      value = changes.fetch(:message_defaults)
      case value
      when Hash then options[:message_defaults] = @message_defaults.merge(normalize_defaults(value))
      else raise ArgumentError, "Message defaults must be a hash"
      end
    end

    def inspect
      "#<Unisender::Configuration>"
    end

    def check_open!
      @state.check_open!
    end

    def close
      @state.close do
        transport = @transport
        if @owns_transport
          case transport
          when PersistentTransport then transport.close
          end
        end
      end
    end

    private

    def clear_alternative(options, changes, object, settings)
      if changes.key?(object)
        settings.each { |key| options.delete(key) }
      elsif settings.any? { |key| changes.key?(key) }
        options.delete(object)
      end
    end

    def build_transport(transport, open_timeout, read_timeout, write_timeout, persistent)
      validate_conflicts(transport, [open_timeout, read_timeout, write_timeout])
      raise ArgumentError, "Persistent mode conflicts with an explicit transport" if transport && persistent

      factory = persistent ? PersistentTransport : Transport
      transport || factory.new(**timeout_options(open_timeout, read_timeout, write_timeout))
    end

    def initialize_resources(limiter, transport)
      @rate_limiter = limiter
      @owns_transport = case transport
                        when nil then true
                        else false
                        end
      @state = ClientState.new
    end

    def timeout_options(open_timeout, read_timeout, write_timeout)
      defaults = { open_timeout: 5, read_timeout: 60, write_timeout: 30 }
      defaults.merge({ open_timeout:, read_timeout:, write_timeout: }.compact)
    end

    def build_retry(policy, max_retries, max_elapsed)
      validate_conflicts(policy, [max_retries, max_elapsed])
      policy || RetryPolicy.new(max_retries: max_retries.nil? ? 0 : max_retries,
                                max_elapsed: max_elapsed.nil? ? 60 : max_elapsed)
    end

    def credentials(key, language)
      unless key.is_a?(String) && !key.strip.empty? && !key.match?(/[\r\n]/)
        raise ArgumentError, "api_key must be a nonempty string without line breaks"
      end
      raise ArgumentError, "language must be en or ru" unless %w[en ru].include?(language.to_s)

      [key.dup.freeze, language.to_s.freeze]
    end

    def validate_conflicts(object, settings)
      return unless object && settings.any? { |value| !value.nil? }

      raise ArgumentError, "Explicit objects cannot be combined with their configuration options"
    end

    def defaults(values)
      normalize_defaults(values).compact.freeze
    end

    def normalize_defaults(values)
      names = values.keys.map(&:to_sym)
      unless names.uniq == names && names.all? { |key| DEFAULT_KEYS.include?(key) }
        raise ArgumentError, "Unknown or duplicate message default"
      end

      values.to_h { |key, value| [key.to_sym, default_value(value)] }
    end

    def default_value(value)
      return nil if value.nil?
      raise ArgumentError, "Message defaults must be strings or nil" unless value.is_a?(String)

      value.dup.freeze
    end
  end
end
