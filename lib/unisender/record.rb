# frozen_string_literal: true

module Unisender
  # Immutable result fields, including fields added by the service.
  class Record
    def initialize(data)
      @values = data.transform_values { |value| self.class.decode(value) }
      normalize
      @values.freeze
      freeze
    end

    def self.decode(value)
      case value
      when Hash then Record.new(value)
      when Array then value.map { |item| decode(item) }.freeze
      else value.dup.freeze
      end
    end

    def [](key) = @values[key.to_s]

    def fetch(key, *defaults, &block)
      raise ArgumentError, "Expected at most one default" if defaults.size > 1
      return @values.fetch(key.to_s) { yield(key) } if block
      return @values.fetch(key.to_s) if defaults.empty?

      @values.fetch(key.to_s, defaults.fetch(0))
    end

    def key?(key) = @values.key?(key.to_s)

    def keys = @values.keys

    def values = @values.values

    def dig(key, *path)
      @values.dig(key.to_s, *path)
    end

    def to_h
      @values.transform_values { |value| Record.copy(value) }
    end

    alias to_hash to_h

    def as_json(options = nil)
      Serialization.payload(self, options)
    end

    def to_json(state = nil)
      Serialization.json(self, state)
    end

    def ==(other)
      case other
      when Record then self.class == other.class && to_h == other.to_h
      else false
      end
    end

    def eql?(other)
      case other
      when Record then self.class == other.class && to_h.eql?(other.to_h)
      else false
      end
    end

    def hash = [self.class, to_h].hash

    def inspect = "#<#{self.class}>"

    def self.copy(value)
      case value
      when Record then value.to_h
      when Array then value.map { |item| copy(item) }
      when Hash then value.transform_values { |item| copy(item) }
      else value.dup
      end
    end

    protected

    def child(model, data, path)
      model.new(data)
    rescue InvalidResponseError => e
      raise e.prepend_path(path), cause: nil
    end

    def normalize; end

    def text(name)
      value = self[name]
      return value if value.nil? || value.is_a?(String)

      invalid!(name, expected_type: "String or nil")
    end

    def text!(name)
      text(name) || invalid!(name, expected_type: "String")
    end

    def identifier!(name)
      value = self[name]
      return value if value.is_a?(String) || value.is_a?(Integer)

      invalid!(name, expected_type: "String or Integer")
    end

    def integer!(name)
      value = self[name]
      return value if value.is_a?(Integer)
      return Integer(value, 10) if value.is_a?(String) && value.match?(/\A\d+\z/)

      invalid!(name, expected_type: "Integer")
    end

    def integer(name)
      self[name].nil? ? nil : integer!(name)
    end

    def number(name)
      value = self[name]
      return value if value.nil? || value.is_a?(Integer) || value.is_a?(Float)

      invalid!(name, expected_type: "Number or nil")
    end

    def invalid!(name, expected_type: "documented value")
      raise InvalidResponseError.new("Invalid result field", path: name, expected_type:,
                                                             actual_type: Diagnostics.type_name(self[name])), cause: nil
    end
  end

  # A fetched collection; Enumerable never makes further requests.
  class CollectionResponse < Response
    include Enumerable

    def each(&block)
      return result.each unless block

      result.each(&block)
    end

    # Track omission separately because Array rejects an explicitly nil length.
    def [](index, length = begin
      omitted = true
      nil
    end)
      return index.is_a?(Range) ? result[index] : result.at(index) if omitted

      raise TypeError, "Invalid slice arguments" if index.is_a?(Range) || length.nil?

      result[index, length]
    end

    def at(index)
      result.at(index)
    end

    def fetch(index, *defaults, &block)
      raise ArgumentError, "Expected at most one default" if defaults.size > 1
      return result.fetch(index, &block) if block
      return result.fetch(index) if defaults.empty?

      result.fetch(index, defaults.fetch(0))
    end

    def size
      result.size
    end

    alias length size

    def empty?
      result.empty?
    end
  end

  # A typed object with explicit field readers supplied by its subclass.
  class ObjectResponse < Response
    def key?(key)
      result.key?(key)
    end

    def keys
      result.keys
    end

    def values
      result.values
    end

    def [](key)
      result[key]
    end

    def fetch(key, *defaults, &)
      result.fetch(key, *defaults, &)
    end

    def to_h
      result.to_h
    end

    def dig(key, *path)
      result.dig(key, *path)
    end
  end
end
