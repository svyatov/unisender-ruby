# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class EventBatchSizesTest < Minitest::Test
  def test_large_events_are_split_before_sending
    replies = Array.new(2) { ScriptedTransport.reply({ "success" => true }) }
    transport = ScriptedTransport.new(*replies)
    client = Unisender::Client.new(api_key: "test-key", transport:)
    event = { name: "purchase", email: "a@b.test", note: "x" * 70_000 }
    report = client.track_events_in_batches(events: [event, event])

    assert_equal 2, report.completed_batches
    assert(transport.requests.all? { |request| request[:body].bytesize <= Unisender::EventPayload::MAX_BYTES })
  end

  def test_oversized_event_has_an_input_index_and_sends_nothing
    transport = ScriptedTransport.new
    client = Unisender::Client.new(api_key: "test-key", transport:)
    error = assert_raises(Unisender::BatchError) do
      client.track_events_in_batches(events: [{ name: "purchase", email: "a@b.test", note: "x" * 140_000 }])
    end

    assert_equal ["events[0]", 0...1, false], [error.error.field, error.failed_range, error.report.uncertain?]
    assert_empty transport.requests
  end

  def test_historical_event_time_is_formatted_without_changing_other_fields
    payload = Unisender::EventPayload.encode([{ name: "sale", email: "a@b.test", created: Time.utc(2026, 1, 2) }])

    assert_equal "2026-01-02 00:00:00", JSON.parse(payload).fetch("events").first.fetch("created")
  end

  def test_streaming_input_failure_preserves_completed_batches
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => { "invalid" => 0, "total" => 1 } }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    rows = [{ email: "a@b.test" }, { email: "b@b.test", Name: "extra" }].each
    error = assert_raises(Unisender::BatchError) { client.import_contacts_in_batches(records: rows, batch_size: 1) }

    assert_equal [1, 1...2, false], [error.report.completed_batches, error.failed_range, error.report.uncertain?]
  end
end
