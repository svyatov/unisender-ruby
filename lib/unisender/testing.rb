# frozen_string_literal: true

require_relative "../unisender"
require_relative "testing/assertions"
require_relative "testing/fixtures"

module Unisender
  # Optional deterministic transport support for application tests.
  module Testing
    Request = Data.define(:uri, :headers, :body)
    Reply = Data.define(:operation, :response, :expected_form, :expected_json)

    # Explicit body access is private data; inspection and form access redact credentials.
    class Request
      def operation
        uri.host == "event.unisender.com" ? "track_events" : uri.path.to_s.split("/api/", 2).last.to_s
      end

      def form
        URI.decode_www_form(body).to_h.except("api_key")
      end

      def json
        JSON.parse(body) # : json
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

      # rubocop:disable-next Metrics/ParameterLists -- Expectations belong to their queued response.
      def enqueue(data:, http_status: 200, headers: {}, operation: nil, expected_form: nil, expected_json: nil)
        reply = HTTPResponse.new(status: http_status, headers:, body: JSON.generate(data))
        enqueue_response(reply, operation:, expected_form:, expected_json:)
      end

      def enqueue_response(response, operation: nil, expected_form: nil, expected_json: nil)
        Assertions.validate(expected_form, expected_json)
        @replies << Reply.new(operation:, response:, expected_form:, expected_json:)
        self
      end

      def requests
        @requests.dup.freeze
      end

      def verify!
        raise "#{@replies.size} queued response(s) were not consumed" unless @replies.empty?

        self
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
        if reply.operation && reply.operation != request.operation
          expected = Error.safe_operation(reply.operation) || "request"
          actual = Error.safe_operation(request.operation) || "request"
          raise "Unexpected request: expected #{expected}, received #{actual}"
        end

        Assertions.check(request, reply.expected_form, reply.expected_json)
        reply.response
      end
    end
  end
end
