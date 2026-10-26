# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class TestingSupportTest < Minitest::Test
  def test_fake_transport_records_requests_and_redacts_inspection
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] }, operation: "getLists")
    client = Unisender::Client.new(api_key: "private-key", transport:)
    client.get_lists

    assert_equal "getLists", transport.requests.first.operation
    refute transport.requests.first.form.key?("api_key")
    refute_includes [transport, transport.requests].inspect, "private-key"
  end

  def test_queued_error_and_unexpected_requests
    transport = Unisender::Testing::Transport.new.enqueue_response(Unisender::TimeoutError.new("Timeout"))
    client = Unisender::Client.new(api_key: "test-key", transport:)

    assert_raises(Unisender::TimeoutError) { client.get_lists }
    assert_raises(RuntimeError) { client.get_lists }
  end

  def test_operation_mismatch_and_event_endpoint
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] }, operation: "getTags")
    client = Unisender::Client.new(api_key: "test-key", transport:)

    assert_raises(RuntimeError) { client.get_lists }
    transport.enqueue(data: { "success" => true }, operation: "track_events")
    client.track_events(events: [{ name: "sale", email: "a@b.test" }])

    assert_equal "track_events", transport.requests.last.operation
  end
end
