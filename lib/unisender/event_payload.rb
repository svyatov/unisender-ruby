# frozen_string_literal: true

module Unisender
  # Event Tracking uses JSON with its own batch and payload limits.
  module EventPayload
    MAX_BYTES = 130 * 1024

    def self.encode(events)
      raise ValidationError.new(field: "events", code: :invalid_count) unless (1..25).cover?(events.size)

      body = serialize(events)
      raise ValidationError.new(field: "events", code: :too_large) if body.bytesize > MAX_BYTES

      body
    end

    def self.serialize(events)
      normalized = events.map { |event| validate(normalize(with_timestamp(event), 0)) }
      JSON.generate({ "events" => normalized })
    rescue EncodingError, JSON::GeneratorError
      raise ValidationError.new(field: "events", code: :invalid_encoding), cause: nil
    end

    def self.with_timestamp(event)
      return event unless event.is_a?(Hash)

      event.to_h do |key, value|
        item = key.to_s == "created" && value.is_a?(Time) ? value.getutc.strftime("%Y-%m-%d %H:%M:%S") : value
        [key, item]
      end
    end

    def self.validate(event)
      raise ValidationError.new(field: "events", code: :invalid_type) unless event.is_a?(Hash)
      raise ValidationError.new(field: "events", code: :too_many_fields) if event.size > 25

      validate_name(event["name"])
      validate_email(event["email"])
      event
    end

    def self.validate_name(name)
      return if name.is_a?(String) && (1..40).cover?(name.size)

      raise ValidationError.new(field: "events.name", code: :invalid_name)
    end

    def self.validate_email(email)
      return if email.is_a?(String) && email.ascii_only? && email.match?(/\A[^\s@]+@[^\s@]+\z/)

      raise ValidationError.new(field: "events.email", code: :invalid_email)
    end

    def self.normalize(value, depth)
      raise ValidationError.new(field: "events", code: :too_deep) if depth > 32

      case value
      when Hash then normalize_hash(value, depth)
      when Array then value.map { |item| normalize(item, depth + 1) }
      when String then value.encode(Encoding::UTF_8)
      when Integer, Float, true, false, nil then value
      else raise ValidationError.new(field: "events", code: :invalid_type)
      end
    end

    def self.normalize_hash(value, depth)
      # @type var result: Hash[String, json]
      result = {}
      value.each do |key, item|
        name = key.to_s.encode(Encoding::UTF_8)
        raise ValidationError.new(field: "events", code: :duplicate_key) if result.key?(name)

        result[name] = normalize(item, depth + 1)
      end
      result
    end
  end
end
