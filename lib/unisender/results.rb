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
      shape_error("Boolean", response.result, "result") unless [true, false].include?(response.result)

      response
    end

    def self.validate_container(method, value)
      collection = COLLECTION_OPERATIONS.include?(method)
      return if collection == value.is_a?(Array)

      shape_error(collection ? "Array" : "Hash", value, "result")
    end

    def self.normalize(method, value)
      return normalize_send(method, value) if %w[sendSms sendEmail].include?(method)
      return single_message(value) if method == "getMessage"
      return rows(value) if method == "getVisitedLinks"
      return {} if EMPTY_OPERATIONS.include?(method) && value == []

      value
    end

    def self.normalize_send(method, value)
      return value.is_a?(Hash) ? [value] : value if method == "sendSms"

      value.is_a?(Array) ? { "recipients" => value } : value
    end

    def self.single_message(value)
      raise NotFoundError, "Message not found" if value.is_a?(Array) && value.empty?

      shape_error("Array with one message", value, "result") unless value.is_a?(Array) && value.size == 1

      value.first
    end

    def self.wrap(value, model, wrapper, response)
      if value.is_a?(Array)
        records = value.each_with_index.map { |item, index| object(model, item, "result[#{index}]") }.freeze
        CollectionResponse.new(data: response.data, status: response.http_status, headers: response.headers,
                               result: records)
      else
        wrapper.new(data: response.data, status: response.http_status, headers: response.headers,
                    result: object(model, value))
      end
    end

    def self.object(model, value, path = "result")
      unless value.is_a?(Hash)
        raise InvalidResponseError.new("Expected result object", expected_type: "Hash",
                                                                 actual_type: Diagnostics.type_name(value))
      end

      model.new(value)
    rescue InvalidResponseError => e
      raise e.prepend_path(path), cause: nil
    end

    def self.rows(value)
      shape_error("Hash", value, "result") unless value.is_a?(Hash)
      names, data = value.values_at("fields", "data")
      shape_error("Array", names, "result.fields") unless names.is_a?(Array)
      shape_error("Array", data, "result.data") unless data.is_a?(Array)

      fields = field_names(names)
      data.each_with_index.map { |row, index| row_object(fields, row, index) }
    end

    def self.row_object(fields, row, index)
      unless row.is_a?(Array) && row.size == fields.size
        shape_error("Array with #{fields.size} cells", row, "result.data[#{index}]")
      end

      fields.zip(row).to_h
    end

    def self.field_names(value)
      value.each_with_index do |name, index|
        shape_error("String", name, "result.fields[#{index}]") unless name.is_a?(String)
      end
      shape_error("Unique field names", value, "result.fields") unless value.uniq == value

      value # : Array[String]
    end

    def self.shape_error(expected, value, path)
      raise InvalidResponseError.new("Unexpected result shape", path:, expected_type: expected,
                                                                actual_type: Diagnostics.type_name(value))
    end
  end
end
