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

    def [](key)
      @values[key.to_s]
    end

    def fetch(key, *defaults, &block)
      raise ArgumentError, "Expected at most one default" if defaults.size > 1
      return @values.fetch(key.to_s) { yield(key) } if block
      return @values.fetch(key.to_s) if defaults.empty?

      @values.fetch(key.to_s, defaults.fetch(0))
    end

    def key?(key)
      @values.key?(key.to_s)
    end

    def keys
      @values.keys
    end

    def values
      @values.values
    end

    def dig(key, *path)
      @values.dig(key.to_s, *path)
    end

    def to_h
      @values.transform_values { |value| Record.copy(value) }
    end

    alias to_hash to_h

    def as_json(_options = nil)
      to_h
    end

    def to_json(state = nil)
      as_json.to_json(state)
    end

    def ==(other)
      case other
      when Record then to_h == other.to_h
      when Hash then to_h == other
      else false
      end
    end

    def inspect
      "#<#{self.class}>"
    end

    def self.copy(value)
      case value
      when Record then value.to_h
      when Array then value.map { |item| copy(item) }
      when Hash then value.transform_values { |item| copy(item) }
      else value.dup
      end
    end

    protected

    def normalize; end

    def text(name)
      value = self[name]
      return value if value.nil? || value.is_a?(String)

      invalid!(name)
    end

    def text!(name)
      text(name) || invalid!(name)
    end

    def identifier!(name)
      value = self[name]
      return value if value.is_a?(String) || value.is_a?(Integer)

      invalid!(name)
    end

    def integer!(name)
      value = self[name]
      return value if value.is_a?(Integer)
      return Integer(value, 10) if value.is_a?(String) && value.match?(/\A\d+\z/)

      invalid!(name)
    end

    def integer(name)
      self[name].nil? ? nil : integer!(name)
    end

    def number(name)
      value = self[name]
      return value if value.nil? || value.is_a?(Integer) || value.is_a?(Float)

      invalid!(name)
    end

    def invalid!(name)
      raise InvalidResponseError, "Invalid result field: #{name}", cause: nil
    end
  end

  # A fetched collection; Enumerable never makes further requests.
  class CollectionResponse < Response
    include Enumerable

    def each(&block)
      return result.each unless block

      result.each(&block)
    end

    def [](index, length = nil)
      if length
        raise TypeError, "A slice offset must be an Integer" unless index.is_a?(Integer)

        result[index, length]
      elsif index.is_a?(Integer)
        result.at(index)
      else
        result[index]
      end
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
