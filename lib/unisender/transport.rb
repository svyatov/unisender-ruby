# frozen_string_literal: true

require "net/http"
require "openssl"

module Unisender
  # Verified HTTPS transport with explicit timeouts and no implicit retries.
  class Transport
    def initialize(open_timeout: 5, read_timeout: 60, write_timeout: 30, http_factory: nil)
      [open_timeout, read_timeout, write_timeout].each do |timeout|
        unless timeout.is_a?(Numeric) && timeout.positive? && timeout.finite?
          raise ArgumentError, "Timeouts must be positive finite numbers"
        end
      end
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @write_timeout = write_timeout
      @http_factory = http_factory || ->(uri) { Net::HTTP.new(uri.hostname.to_s, uri.port) }
    end

    def post(uri, headers:, body:, execution: nil)
      exchange(uri, headers:, body:, execution:)
    rescue Timeout::Error
      raise TimeoutError, "UniSender request timed out", cause: nil
    rescue OpenSSL::SSL::SSLError
      raise TransportError, "UniSender TLS connection failed", cause: nil
    rescue IOError, SystemCallError, SocketError
      raise TransportError.new("UniSender connection failed", retryable: true), cause: nil
    end

    private

    def exchange(uri, headers:, body:, execution:)
      request = Net::HTTP::Post.new(uri, headers)
      request.body = body
      response = perform(uri, request, execution:)
      headers = response.to_hash.transform_values { |items| items.join(", ") }
      HTTPResponse.new(status: response.code.to_i, headers:, body: response.body.to_s)
    end

    def perform(uri, request, execution:)
      configured_http(uri, execution:).request(request)
    end

    def configured_http(uri, execution: nil)
      http = @http_factory.call(uri)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      configure_timeouts(http, execution)
      http.max_retries = 0
      http
    end

    def configure_timeouts(http, execution)
      remaining = execution&.remaining
      http.open_timeout = remaining ? [@open_timeout, remaining].min : @open_timeout
      http.read_timeout = remaining ? [@read_timeout, remaining].min : @read_timeout
      http.write_timeout = remaining ? [@write_timeout, remaining].min : @write_timeout
    end
  end
end
