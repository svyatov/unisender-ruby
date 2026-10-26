# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class TestingSupportTest < Minitest::Test
  def test_verify_requires_every_queued_reply_to_be_consumed
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] })

    assert_match(/1 queued response/, assert_raises(RuntimeError) { transport.verify! }.message)
    Unisender::Client.new(api_key: "test-key", transport:).get_lists

    assert_same transport, transport.verify!
  end

  def test_event_json_and_mismatch_diagnostics_exclude_credentials
    transport = Unisender::Testing::Transport.new.enqueue(data: {}, operation: "secret-value")
    client = Unisender::Client.new(api_key: "private-key", transport:)
    error = assert_raises(RuntimeError) { client.track_events(events: [{ name: "sale", email: "a@b.test" }]) }
    assert_equal "Unexpected request: expected request, received track_events", error.message
    assert_equal "sale", transport.requests.first.json.fetch("events").fetch(0).fetch("name")
  end

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
