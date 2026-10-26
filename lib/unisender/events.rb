# frozen_string_literal: true

module Unisender
  # JSON Event Tracking endpoint.
  class Client
    def track_events(events:)
      body = EventPayload.encode(events)
      headers = { "Content-Type" => "application/json", "Authorization" => "Bearer #{@api_key}" }
      http = @transport.post(URI("https://event.unisender.com/v1/events/"), headers:, body:)
      parse_event_response(http)
    rescue Error => e
      raise e.with_operation("track_events"), cause: nil
    end

    private

    def parse_event_response(http)
      response = Response.new(data: Protocol.decode(http), status: http.status, headers: http.headers)
      raise EventError, response, cause: nil unless (200..299).cover?(http.status)
      raise InvalidResponseError, "Missing event success status", cause: nil unless response.data["success"] == true

      Results.build("track_events", response) # : ObjectResponse[Record]
    end
  end
end
