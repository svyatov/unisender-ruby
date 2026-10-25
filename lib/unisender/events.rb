# frozen_string_literal: true

module Unisender
  # JSON Event Tracking endpoint.
  class Client
    def track_events(events:)
      body = EventPayload.encode(events)
      headers = { "Content-Type" => "application/json", "Authorization" => "Bearer #{@api_key}" }
      http = @transport.post(URI("https://event.unisender.com/v1/events/"), headers:, body:)
      response = Response.new(data: Protocol.decode(http), status: http.status, headers: http.headers)
      raise EventError, response, cause: nil unless (200..299).cover?(http.status)
      unless response.data["success"] == true
        raise InvalidResponseError, "Missing Event Tracking success status", cause: nil
      end

      response
    end
  end
end
