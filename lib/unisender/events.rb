# frozen_string_literal: true

module Unisender
  # JSON Event Tracking endpoint.
  class Client
    def track_events(events:)
      body = EventPayload.encode(events)
      headers = { "Content-Type" => "application/json", "Authorization" => "Bearer #{@api_key}" }
      exchange("track_events", URI("https://event.unisender.com/v1/events/"), headers:, body:) do |http|
        parse_event_response(http)
      end
    rescue Error, ValidationError => e
      raise e.with_operation("track_events"), cause: nil
    end

    private

    def parse_event_response(http)
      response = Response.new(data: Protocol.decode(http), status: http.status, headers: http.headers)
      raise EventError, response, cause: nil unless (200..299).cover?(http.status)
      raise InvalidResponseError, "Missing event success status", cause: nil unless response.data["success"] == true

      EventResponse.new(data: response.data, status: response.http_status, headers: response.headers,
                        result: EventResult.new(response.data))
    end
  end
end
