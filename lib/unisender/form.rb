# frozen_string_literal: true

module Unisender
  # UniSender accepts indexed form fields, not JSON, including for attachments.
  module Form
    def self.encode(params)
      URI.encode_www_form(pairs(params, nil, 0))
    rescue EncodingError
      raise ArgumentError, "Parameters must contain valid UTF-8 text", cause: nil
    end

    def self.pairs(value, prefix, depth)
      raise ArgumentError, "Parameters are nested too deeply" if depth > 32

      case value
      when Hash
        hash_pairs(value, prefix, depth)
      when Array
        value.each_with_index.flat_map { |item, index| pairs(item, "#{prefix}[#{index}]", depth + 1) }
      else
        [[prefix.to_s, scalar(value, prefix.to_s)]]
      end
    end

    def self.hash_pairs(value, prefix, depth)
      keys = value.keys.map(&:to_s)
      raise ArgumentError, "Duplicate parameter names" unless keys.uniq.size == keys.size

      value.flat_map do |key, item|
        name = key.to_s.encode(Encoding::UTF_8)
        raise ArgumentError, "Parameter names cannot contain brackets" if name.match?(/[\[\]]/)
        next [] if item.nil?

        pairs(item, prefix ? "#{prefix}[#{name}]" : name, depth + 1)
      end
    end

    def self.scalar(value, name)
      case value
      when String
        name.start_with?("attachments[") ? value.b : text(value)
      when true then "1"
      when false then "0"
      when nil then ""
      else numeric(value)
      end
    end

    def self.text(value)
      raise ArgumentError, "Parameters must contain valid UTF-8 text" unless value.valid_encoding?

      value.encode(Encoding::UTF_8)
    end

    def self.numeric(value)
      case value
      when Integer then value.to_s
      when Float
        raise ArgumentError, "Numeric parameters must be finite" unless value.finite?

        value.to_s
      else
        raise ArgumentError, "Unsupported parameter type"
      end
    end
  end
end
