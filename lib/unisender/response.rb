# frozen_string_literal: true

require "json"

module Unisender
  # Complete HTTP response at the transport boundary.
  HTTPResponse = Data.define(:status, :headers, :body)

  # Transport metadata with a payload-free inspection representation.
  class HTTPResponse
    def inspect
      "#<Unisender::HTTPResponse status=#{status}>"
    end

    alias to_s inspect
  end

  # A successful response. JSON values retain their original types and string keys.
  class Response
    # @type var empty: Array[json]
    empty = []
    EMPTY_WARNINGS = empty.freeze

    attr_reader :data, :status, :headers

    def initialize(data:, status:, headers:)
      @data = immutable_hash(data)
      @status = status
      @headers = headers.to_h { |key, value| [key.dup.freeze, value.dup.freeze] }.freeze
      freeze
    end

    def result
      @data.fetch("result", @data)
    end

    def warnings
      @data.fetch("warnings", EMPTY_WARNINGS)
    end

    def inspect
      "#<Unisender::Response status=#{@status}>"
    end

    private

    def immutable_hash(value)
      value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
    end

    def immutable(value)
      case value
      when Hash
        immutable_hash(value)
      when Array
        value.map { |item| immutable(item) }.freeze
      else
        value.dup.freeze
      end
    end
  end
end
