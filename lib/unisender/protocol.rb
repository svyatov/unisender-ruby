# frozen_string_literal: true

module Unisender
  # Keeps HTTP failures separate from the API's success/error envelope.
  module Protocol
    def self.parse(http)
      data = decode(http)
      response = Response.new(data:, status: http.status, headers: http.headers)
      raise HTTPError, response, cause: nil unless (200..299).cover?(http.status)
      raise APIError, response, cause: nil if data.key?("error")
      raise InvalidResponseError, "Missing API result", cause: nil unless data.key?("result")

      response
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
