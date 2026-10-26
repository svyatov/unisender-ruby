# frozen_string_literal: true

module Unisender
  # Filtering selects root fields only; nested values remain detached copies.
  module Serialization
    OPTIONS = %w[only except].freeze
    def self.payload(value, options = nil)
      data = Record.copy(value)
      fields = options_for(options)
      fields.empty? ? data : filter(data, fields)
    end

    def self.json(value, options = nil)
      return payload(value).to_json(options) if options.is_a?(JSON::State)

      payload(value, options).to_json
    end

    def self.options_for(options)
      return {} if options.nil?
      raise ArgumentError, "Serialization options must be a hash" unless options.is_a?(Hash)

      result = {} # : Hash[Symbol, Array[String]]
      options.each do |key, value|
        unless OPTIONS.include?(key.to_s) && !result.key?(key.to_s.to_sym)
          raise ArgumentError, "Unknown or duplicate serialization option"
        end

        result[key.to_s.to_sym] = field_names(value)
      end
      result
    end

    def self.field_names(value)
      names = value.is_a?(Array) ? value : [value]
      unless names.all? { |name| name.is_a?(String) || name.is_a?(Symbol) }
        raise ArgumentError, "Serialization field names must be strings or symbols"
      end

      names.map(&:to_s)
    end

    def self.filter(data, fields)
      case data
      when Array then data.map { |item| filter(item, fields) }
      when Hash
        only = fields[:only]
        result = only ? data.slice(*only) : data
        result.except(*fields.fetch(:except, []))
      else raise ArgumentError, "Serialization filters require object results"
      end
    end
  end
end
