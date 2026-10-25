# frozen_string_literal: true

module Unisender
  # Keeps HTTP failures separate from the API's success/error envelope.
  module Protocol
    def self.parse(http, method: nil)
      data = decode(http)
      response = Response.new(data:, status: http.status, headers: http.headers)
      raise HTTPError, response, cause: nil unless (200..299).cover?(http.status)
      raise APIError, response, cause: nil if data.key?("error")
      raise InvalidResponseError, "Missing API result", cause: nil unless result?(data, method)

      response
    end

    # These method pages document success objects without the usual result envelope.
    # https://www.unisender.com/ru/support/api/messages/sendtestemail/
    # https://www.unisender.com/ru/support/api/inputs/updatefield/
    def self.result?(data, method)
      return true if data.key?("result")

      case method
      when "sendTestEmail" then data["message"].is_a?(String)
      when "updateField" then data["id"].is_a?(Integer)
      else false
      end
    end

    def self.decode(http)
      # @type var data: json
      data = JSON.parse(http.body)
      unless data.is_a?(Hash)
        raise InvalidResponseError, "Expected a JSON object", cause: nil if (200..299).cover?(http.status)

        return {}
      end

      data.delete("result") if data.key?("error")
      data
    rescue JSON::ParserError, EncodingError
      raise InvalidResponseError, "Invalid JSON response", cause: nil if (200..299).cover?(http.status)

      {}
    end
  end
end
