# frozen_string_literal: true

require_relative "../unisender"
require "digest"
require "zlib"
require "stringio"

module Unisender
  # Rejected inbound data never appears in exception messages.
  class WebhookError < Error
    attr_reader :reason

    def initialize(reason)
      @reason = reason
      super("Invalid webhook: #{reason}")
    end

    def category
      :invalid_webhook
    end
  end

  # A notification event keeps its schema-specific fields in event_data.
  class WebhookEvent < Record
    def event_name
      text!("event_name")
    end

    def event_time
      text!("event_time")
    end

    def event_data
      value = self["event_data"]
      raise WebhookError, :invalid_event unless value.is_a?(Record)

      value
    end

    protected

    def normalize
      event_name
      event_time
      event_data
    end
  end

  # Events grouped by the account login from the notification.
  class WebhookUser < Record
    def login
      text!("login")
    end

    def events
      raise WebhookError, :conflicting_events if key?("events") && key?("Events")

      values = self[key?("events") ? "events" : "Events"]
      raise WebhookError, :unsupported_shape unless values.is_a?(Array)

      Outcomes.records(values).map { |event| WebhookEvent.new(event.to_h) }
    end

    protected

    def normalize
      login
      raise WebhookError, :unsupported_shape unless key?("events") || key?("Events")

      events
    end
  end

  # Authenticated notification payload with typed user and event readers.
  class WebhookNotification < Record
    def users
      Outcomes.records(self["events_by_user"]).map { |user| WebhookUser.new(user.to_h) }
    end

    def events
      users.flat_map(&:events)
    end

    protected

    def normalize
      raise WebhookError, :unsupported_shape unless self["events_by_user"].is_a?(Array)

      users
    end
  end

  # The documented signature covers original decompressed JSON bytes.
  module Webhooks
    TOKENS = /"(?:[^"\\]|\\.)*"|[{}\[\]:,]/m

    # The token walk rejects duplicate keys even on older JSON parsers.
    class ObjectKeys
      attr_reader :key

      def initialize
        @seen = {}
        @key = nil
      end

      def register(token)
        return if @key

        key = JSON.parse(token) # : String
        raise WebhookError, :duplicate_key if @seen.key?(key)

        @seen[key] = true
        @key = key
      end

      def next_key
        @key = nil
      end
    end

    # rubocop:disable-next Metrics/ParameterLists -- Independent receiver limits are explicit.
    def self.verify(body:, api_key:, content_encoding: nil, max_bytes: 1_048_576,
                    max_decompressed_bytes: 4_194_304, max_events: 10_000)
      validate_limits(max_bytes, max_decompressed_bytes, max_events)
      raise WebhookError, :too_large if body.bytesize > max_bytes

      bytes = decompress(body, content_encoding, max_decompressed_bytes)
      data = decode(bytes)
      authenticate(bytes, data, api_key)
      notification = WebhookNotification.new(data)
      raise WebhookError, :too_many_events if notification.events.size > max_events

      notification
    rescue JSON::ParserError, EncodingError, InvalidResponseError, TypeError, ArgumentError
      raise WebhookError, :malformed_payload, cause: nil
    end

    def self.decode(bytes)
      data = JSON.parse(bytes, max_nesting: 64) # : json
      raise WebhookError, :unsupported_shape unless data.is_a?(Hash)

      data
    end

    def self.validate_limits(*limits)
      return if limits.all? { |value| value.is_a?(Integer) && value.positive? }

      raise WebhookError, :invalid_limits
    end

    def self.decompress(body, encoding, limit)
      case encoding
      when nil, "", "identity" then bounded(body, limit)
      when "gzip" then inflate(body, limit)
      else raise WebhookError, :unsupported_encoding
      end
    rescue Zlib::Error, EOFError
      raise WebhookError, :invalid_gzip, cause: nil
    end

    def self.inflate(body, limit)
      gzip = Zlib::GzipReader.new(StringIO.new(body))
      begin
        result = bounded(gzip.read(limit + 1).to_s, limit)
        raise WebhookError, :trailing_data unless gzip.unused.to_s.empty?

        result
      ensure
        gzip.close
      end
    end

    def self.bounded(body, limit)
      raise WebhookError, :too_large if body.bytesize > limit

      text = body.dup.force_encoding(Encoding::UTF_8)
      raise WebhookError, :invalid_encoding unless text.valid_encoding?

      text
    end

    def self.authenticate(bytes, data, api_key)
      auth = auth_value(data)
      start, finish = auth_span(bytes)
      signed = bytes[0...start].to_s + JSON.generate(api_key) + bytes[finish..].to_s
      expected = Digest::MD5.hexdigest(signed)
      raise WebhookError, :invalid_auth unless secure_equal?(auth, expected)
    end

    def self.auth_value(data)
      auth = data["auth"]
      raise WebhookError, :invalid_auth unless auth.is_a?(String) && auth.match?(/\A[0-9a-f]{32}\z/)

      auth
    end

    def self.secure_equal?(actual, expected)
      actual.bytes.zip(expected.bytes).reduce(0) { |memo, (a, b)| memo | (a ^ b.to_i) }.zero?
    end

    # rubocop:disable-next Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize -- Preserve JSON spans.
    def self.auth_span(bytes)
      # @type var stack: Array[ObjectKeys?]
      stack = []
      # @type var span: [Integer, Integer]?
      span = nil
      bytes.scan(TOKENS) do
        match = Regexp.last_match # : MatchData
        token = match[0]
        case token
        when "{" then stack << ObjectKeys.new
        when "[" then stack << nil
        when "}", "]" then stack.pop
        when "," then stack.last&.next_key
        when ":" then next
        else
          frame = stack.last
          next unless frame

          span = [Integer(match.begin(0)), Integer(match.end(0))] if stack.size == 1 && frame.key == "auth"
          frame.register(token.to_s)
        end
      end
      span || raise(WebhookError, :invalid_auth)
    end
  end
end
