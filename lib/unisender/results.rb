# frozen_string_literal: true

module Unisender
  # Operation-specific decoding leaves the low-level request path unchanged.
  module Results
    def self.build(method, response)
      return boolean(response) if method == "isContactInLists"

      value = normalize(method, response.result)
      validate_container(method, value)
      model, wrapper = MODELS.fetch(method) { [Record, ObjectResponse] }
      wrap(value, model, wrapper, response)
    end

    def self.boolean(response)
      raise InvalidResponseError, "Expected boolean result" unless [true, false].include?(response.result)

      response
    end

    def self.validate_container(method, value)
      return if method == "sendSms"

      collection = COLLECTION_OPERATIONS.include?(method)
      return if collection == value.is_a?(Array)

      raise InvalidResponseError, "Unexpected result container"
    end

    def self.normalize(method, value)
      return { "recipients" => value } if method == "sendEmail" && value.is_a?(Array)
      return single_message(value) if method == "getMessage"
      return rows(value) if method == "getVisitedLinks"
      return {} if EMPTY_OPERATIONS.include?(method) && value == []

      value
    end

    def self.single_message(value)
      raise NotFoundError, "Message not found" if value.is_a?(Array) && value.empty?
      raise InvalidResponseError, "Expected one message" unless value.is_a?(Array) && value.size == 1

      value.first
    end

    def self.wrap(value, model, wrapper, response)
      if value.is_a?(Array)
        records = value.map { |item| object(model, item) }.freeze
        CollectionResponse.new(data: response.data, status: response.http_status, headers: response.headers,
                               result: records)
      else
        wrapper.new(data: response.data, status: response.http_status, headers: response.headers,
                    result: object(model, value))
      end
    end

    def self.object(model, value)
      raise InvalidResponseError, "Expected result object" unless value.is_a?(Hash)

      model.new(value)
    end

    def self.rows(value)
      unless value.is_a?(Hash) && value["fields"].is_a?(Array) && value["data"].is_a?(Array)
        raise InvalidResponseError, "Expected tabular result"
      end

      fields = field_names(value["fields"])
      value["data"].map { |row| row_object(fields, row) }
    end

    def self.row_object(fields, row)
      raise InvalidResponseError, "Invalid tabular row" unless row.is_a?(Array) && row.size == fields.size

      fields.zip(row).to_h
    end

    def self.field_names(value)
      raise InvalidResponseError, "Invalid tabular fields" unless value.all?(String) && value.uniq == value

      value # : Array[String]
    end
  end
end
