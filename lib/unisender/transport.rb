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

    def post(uri, headers:, body:)
      exchange(uri, headers:, body:)
    rescue Timeout::Error
      raise TimeoutError, "UniSender request timed out", cause: nil
    rescue OpenSSL::SSL::SSLError
      raise TransportError, "UniSender TLS connection failed", cause: nil
    rescue IOError, SystemCallError, SocketError
      raise TransportError.new("UniSender connection failed", retryable: true), cause: nil
    end

    private

    def exchange(uri, headers:, body:)
      request = Net::HTTP::Post.new(uri, headers)
      request.body = body
      response = perform(uri, request)
      headers = response.to_hash.transform_values { |items| items.join(", ") }
      HTTPResponse.new(status: response.code.to_i, headers:, body: response.body.to_s)
    end

    def perform(uri, request)
      configured_http(uri).request(request)
    end

    def configured_http(uri)
      http = @http_factory.call(uri)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout
      http.write_timeout = @write_timeout
      http.max_retries = 0
      http
    end
  end
end
