# frozen_string_literal: true

module Unisender
  # Event Tracking uses JSON with its own batch and payload limits.
  module EventPayload
    MAX_BYTES = 130 * 1024

    def self.encode(events)
      unless events.is_a?(Array)
        raise ValidationError.new(field: "events", code: :invalid_type, expected_type: "Array",
                                  actual_type: Diagnostics.type_name(events))
      end
      raise ValidationError.new(field: "events", code: :invalid_count) unless (1..25).cover?(events.size)

      body = serialize(events)
      raise ValidationError.new(field: "events", code: :too_large) if body.bytesize > MAX_BYTES

      body
    end

    def self.serialize(events)
      normalized = events.each_with_index.map do |event, index|
        path = "events[#{index}]"
        validate(normalize(with_timestamp(event), 0, path), path)
      end
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

    def self.validate(event, path)
      unless event.is_a?(Hash)
        raise ValidationError.new(field: path, code: :invalid_type, expected_type: "Hash",
                                  actual_type: Diagnostics.type_name(event))
      end
      raise ValidationError.new(field: path, code: :too_many_fields) if event.size > 25

      validate_name(event["name"], "#{path}.name")
      validate_email(event["email"], "#{path}.email")
      event
    end

    def self.validate_name(name, path)
      return if name.is_a?(String) && (1..40).cover?(name.size)

      raise ValidationError.new(field: path, code: :invalid_name, expected_type: "String",
                                actual_type: Diagnostics.type_name(name))
    end

    def self.validate_email(email, path)
      return if email.is_a?(String) && email.ascii_only? && email.match?(/\A[^\s@]+@[^\s@]+\z/)

      raise ValidationError.new(field: path, code: :invalid_email, expected_type: "String",
                                actual_type: Diagnostics.type_name(email))
    end

    def self.normalize(value, depth, path)
      raise ValidationError.new(field: path, code: :too_deep) if depth > 32

      case value
      when Hash then normalize_hash(value, depth, path)
      when Array then value.each_with_index.map { |item, index| normalize(item, depth + 1, "#{path}[#{index}]") }
      when String then value.encode(Encoding::UTF_8)
      when Integer, Float, true, false, nil then value
      else raise ValidationError.new(field: path, code: :invalid_type, actual_type: Diagnostics.type_name(value))
      end
    end

    def self.normalize_hash(value, depth, path)
      # @type var result: Hash[String, json]
      result = {}
      value.each do |key, item|
        name = key.to_s.encode(Encoding::UTF_8)
        raise ValidationError.new(field: path, code: :duplicate_key) if result.key?(name)

        field = Diagnostics::FIELDS.include?(name) ? name : "*"
        result[name] = normalize(item, depth + 1, "#{path}.#{field}")
      end
      result
    end
  end
end
