# frozen_string_literal: true

require_relative "../unisender"

module Unisender
  # Optional deterministic transport support for application tests.
  module Testing
    Request = Data.define(:uri, :headers, :body)
    Reply = Data.define(:operation, :response)

    # Explicit body access is private data; inspection and form access redact credentials.
    class Request
      def operation
        uri.host == "event.unisender.com" ? "track_events" : uri.path.to_s.split("/api/", 2).last.to_s
      end

      def form
        URI.decode_www_form(body).to_h.except("api_key")
      end

      def inspect
        "#<Unisender::Testing::Request>"
      end

      alias to_s inspect
    end

    # Queued responses never open a socket.
    class Transport
      def initialize
        @replies = []
        @requests = []
      end

      def enqueue(data:, http_status: 200, headers: {}, operation: nil)
        reply = HTTPResponse.new(status: http_status, headers:, body: JSON.generate(data))
        enqueue_response(reply, operation:)
      end

      def enqueue_response(response, operation: nil)
        @replies << Reply.new(operation:, response:)
        self
      end

      def requests
        @requests.dup.freeze
      end

      def post(uri, headers:, body:)
        request = Request.new(uri: uri.dup.freeze, headers: headers.dup.freeze, body: body.dup.freeze)
        @requests << request
        response = next_response(request)
        raise response if response.is_a?(StandardError)

        response
      end

      def inspect
        "#<Unisender::Testing::Transport>"
      end

      private

      def next_response(request)
        reply = @replies.shift or raise "Unexpected request: no queued response"
        raise "Unexpected request operation" if reply.operation && reply.operation != request.operation

        reply.response
      end
    end
  end
end
