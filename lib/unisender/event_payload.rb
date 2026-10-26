# frozen_string_literal: true

module Unisender
  # Event Tracking uses JSON with its own batch and payload limits.
  module EventPayload
    MAX_BYTES = 130 * 1024

    def self.encode(events)
      raise ArgumentError, "Expected 1 to 25 events" unless (1..25).cover?(events.size)

      body = serialize(events)
      raise ArgumentError, "Event payload exceeds 130 KB" if body.bytesize > MAX_BYTES

      body
    end

    def self.serialize(events)
      normalized = events.map { |event| validate(normalize(with_timestamp(event), 0)) }
      JSON.generate({ "events" => normalized })
    rescue EncodingError, JSON::GeneratorError
      raise ArgumentError, "Events must contain valid JSON values and UTF-8 text", cause: nil
    end

    def self.with_timestamp(event)
      return event unless event.is_a?(Hash)

      event.to_h do |key, value|
        item = key.to_s == "created" && value.is_a?(Time) ? value.getutc.strftime("%Y-%m-%d %H:%M:%S") : value
        [key, item]
      end
    end

    def self.validate(event)
      raise ArgumentError, "Each event must be an object" unless event.is_a?(Hash)
      raise ArgumentError, "Each event may have at most 25 fields" if event.size > 25

      validate_name(event["name"])
      validate_email(event["email"])
      event
    end

    def self.validate_name(name)
      return if name.is_a?(String) && (1..40).cover?(name.size)

      raise ArgumentError, "Event name must contain 1 to 40 characters"
    end

    def self.validate_email(email)
      return if email.is_a?(String) && email.ascii_only? && email.match?(/\A[^\s@]+@[^\s@]+\z/)

      raise ArgumentError, "Event email must be an ASCII email address"
    end

    def self.normalize(value, depth)
      raise ArgumentError, "Events are nested too deeply" if depth > 32

      case value
      when Hash then normalize_hash(value, depth)
      when Array then value.map { |item| normalize(item, depth + 1) }
      when String then value.encode(Encoding::UTF_8)
      when Integer, Float, true, false, nil then value
      else raise ArgumentError, "Unsupported JSON value"
      end
    end

    def self.normalize_hash(value, depth)
      # @type var result: Hash[String, json]
      result = {}
      value.each do |key, item|
        name = key.to_s.encode(Encoding::UTF_8)
        raise ArgumentError, "Duplicate event field names" if result.key?(name)

        result[name] = normalize(item, depth + 1)
      end
      result
    end
  end
end
