# frozen_string_literal: true

module Unisender
  module Testing
    # Compare expected subsets without including payload values in failure messages.
    module Assertions
      def self.check(request, form, json)
        subset!(request.form, form, "") unless form.nil?
        subset!(request.json, json, "") unless json.nil?
      rescue JSON::ParserError
        raise "Expected JSON request body", cause: nil
      end

      def self.validate(form, json)
        raise ArgumentError, "Choose expected_form or expected_json" unless form.nil? || json.nil?
        return unless form&.key?("api_key")

        raise ArgumentError, "Credentials cannot be request expectations"
      end

      def self.subset!(actual, expected, path)
        case expected
        when Hash then hash!(actual, expected, path)
        when Array then array!(actual, expected, path)
        else mismatch!(path) unless actual == expected
        end
      end

      def self.hash!(actual, expected, path)
        mismatch!(path) unless actual.is_a?(Hash)
        expected.each do |key, value|
          child = path.empty? ? key : "#{path}.#{key}"
          mismatch!(child) unless actual.key?(key)
          subset!(actual[key], value, child)
        end
      end

      def self.array!(actual, expected, path)
        mismatch!(path) unless actual.is_a?(Array) && actual.size >= expected.size
        expected.each_with_index { |value, index| subset!(actual[index], value, "#{path}[#{index}]") }
      end

      def self.mismatch!(path)
        raise "Unexpected request value at #{Diagnostics.input_path(path)}"
      end
    end
  end
end
