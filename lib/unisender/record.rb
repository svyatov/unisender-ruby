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

    def fetch(key)
      @values.fetch(key.to_s)
    end

    def dig(key, *path)
      @values.dig(key.to_s, *path)
    end

    def to_h
      @values.transform_values { |value| copy(value) }
    end

    alias to_hash to_h

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

    private

    def copy(value)
      case value
      when Record then value.to_h
      when Array then value.map { |item| copy(item) }
      else value.dup
      end
    end
  end

  # A fetched collection; Enumerable never makes further requests.
  class CollectionResponse < Response
    include Enumerable

    def each(&block)
      return result.each unless block

      result.each(&block)
    end

    def [](index)
      result[index]
    end

    def fetch(index)
      result.fetch(index)
    end

    def size
      result.size
    end

    def empty?
      result.empty?
    end
  end

  # A typed object with explicit field readers supplied by its subclass.
  class ObjectResponse < Response
    def [](key)
      result[key]
    end

    def fetch(key)
      result.fetch(key)
    end

    def dig(key, *path)
      result.dig(key, *path)
    end
  end
end
