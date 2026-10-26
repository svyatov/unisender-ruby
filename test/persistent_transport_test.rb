# frozen_string_literal: true

require "test_helper"
require_relative "support/persistent_https"

class PersistentTransportTest < Minitest::Test
  URI_VALUE = URI("https://api.unisender.com/en/api/getLists")

  def test_reuses_a_verified_tls_connection
    with_server(2) do |server, transport|
      2.times { transport.post(URI_VALUE, headers: {}, body: "api_key=test-key") }

      assert_equal [1, 2], [server.connections, server.requests.size]
    end
  end

  def test_idle_connections_are_replaced
    time = 0.0
    with_server(2, clock: -> { time }, idle_timeout: 10) do |server, transport|
      transport.post(URI_VALUE, headers: {}, body: "")
      time = 10.0
      transport.post(URI_VALUE, headers: {}, body: "")

      assert_equal 2, server.connections
    end
  end

  def test_pid_changes_discard_inherited_connections
    pid = 1
    with_server(2, pid: -> { pid }) do |server, transport|
      transport.post(URI_VALUE, headers: {}, body: "")
      pid = 2
      transport.post(URI_VALUE, headers: {}, body: "")

      assert_equal 2, server.connections
    end
  end

  def test_failed_requests_are_not_replayed
    with_server(3, fail_at: 2) do |server, transport|
      transport.post(URI_VALUE, headers: {}, body: "")

      assert_raises(Unisender::TransportError) { transport.post(URI_VALUE, headers: {}, body: "") }
      transport.post(URI_VALUE, headers: {}, body: "")

      assert_equal [2, 3], [server.connections, server.requests.size]
    end
  end

  def test_close_is_idempotent_and_rejects_requests
    transport = Unisender::PersistentTransport.new
    transport.close

    transport.close

    assert_raises(Unisender::TransportError) { transport.post(URI_VALUE, headers: {}, body: "") }
    assert_raises(ArgumentError) { Unisender::PersistentTransport.new(idle_timeout: 0) }
    assert_raises(ArgumentError) do
      Unisender::PersistentTransport.new.post(URI("https://example.test"), headers: {}, body: "")
    end
  end

  def test_close_ignores_an_already_broken_socket
    with_server(1) do |_server, transport|
      transport.post(URI_VALUE, headers: {}, body: "")
      connection = transport.instance_variable_get(:@connections).values.first.http
      connection.define_singleton_method(:finish) { raise IOError, "closed socket" }
      transport.close

      assert_raises(Unisender::TransportError) { transport.post(URI_VALUE, headers: {}, body: "") }
    end
  end

  def test_inspection_contains_no_connection_details
    assert_equal "#<Unisender::PersistentTransport>", Unisender::PersistentTransport.new.inspect
  end

  private

  def with_server(requests, fail_at: nil, **)
    server = PersistentHTTPS.new(requests:, keep_alive: true, fail_at:)
    transport = Unisender::PersistentTransport.new(**, http_factory: lambda { |_uri|
      http = Net::HTTP.new("localhost", server.port, nil)
      http.cert_store = server.store
      http
    })
    yield server, transport
  ensure
    transport&.close
    server&.close
  end
end
