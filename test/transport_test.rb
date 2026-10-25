# frozen_string_literal: true

require "test_helper"
require "net/http"
require "openssl"
require "socket"
require_relative "support/scripted_transport"
require_relative "support/local_https"

class TransportTest < Minitest::Test
  def test_real_https_post_with_verified_local_certificate
    server = LocalHTTPS.new
    transport = transport_for(server)
    reply = transport.post(URI("https://api.unisender.com/en/api/getLists"),
                           headers: { "Content-Type" => "application/x-www-form-urlencoded" }, body: "api_key=test-key")

    assert_equal [200, { "result" => { "id" => 12 } }], [reply.status, JSON.parse(reply.body)]
    assert_equal ["POST /en/api/getLists HTTP/1.1\r\n", "api_key=test-key"], server.requests.pop
  ensure
    server&.close
  end

  def transport_for(server)
    Unisender::Transport.new(http_factory: lambda { |_uri|
      http = Net::HTTP.new("localhost", server.port, nil)
      http.cert_store = server.store
      http
    })
  end

  def test_timeout_and_transport_failures_are_safe_and_disable_implicit_retries
    [Net::ReadTimeout.new("test-key"), SocketError.new("private-address"),
     OpenSSL::SSL::SSLError.new("private certificate"), EOFError.new("response data")].each do |failure|
      error, http = simulate_failure(failure)

      assert_equal [[true, OpenSSL::SSL::VERIFY_PEER, 2, 3, 4, 0], nil], [http.configuration, error.cause]
      refute_includes error.message, failure.message
    end
  end

  def simulate_failure(failure)
    http = FailingHTTP.new(failure)
    transport = Unisender::Transport.new(open_timeout: 2, read_timeout: 3, write_timeout: 4,
                                         http_factory: ->(_uri) { http })
    expected = failure.is_a?(Net::ReadTimeout) ? Unisender::TimeoutError : Unisender::TransportError
    error = assert_raises(expected) { transport.post(URI("https://api.unisender.com/test"), headers: {}, body: "") }
    [error, http]
  end

  def test_rejects_invalid_timeouts
    [0, -1, Float::INFINITY, Float::NAN, "3"].each do |value|
      assert_raises(ArgumentError) { Unisender::Transport.new(open_timeout: value) }
    end
  end

  class FailingHTTP
    attr_accessor :use_ssl, :verify_mode, :open_timeout, :read_timeout, :write_timeout, :max_retries

    def initialize(failure)
      @failure = failure
    end

    def request(_request)
      raise @failure
    end

    def configuration
      [use_ssl, verify_mode, open_timeout, read_timeout, write_timeout, max_retries]
    end
  end
end
