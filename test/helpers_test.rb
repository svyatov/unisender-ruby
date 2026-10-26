# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class HelpersTest < Minitest::Test
  def test_paginates_lazily_and_preserves_responses
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => [{ "id" => 1 }, { "id" => 2 }] }),
                                      ScriptedTransport.reply({ "result" => [{ "id" => 3 }],
                                                                "warnings" => [{ "warning" => "note" }] }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    pages = client.each_page(:get_campaigns, from: "2026-01-01 00:00:00", page_size: 2)

    assert_empty transport.requests
    assert_equal [[{ "id" => 1 }, { "id" => 2 }], [{ "id" => 3 }]], pages.map(&:as_json)
    assert_equal(%w[0 2], transport.requests.map { |r| URI.decode_www_form(r[:body]).to_h["offset"] })
  end

  def test_batch_import_preserves_completed_responses_when_later_batch_fails
    rows = Array.new(501) { ["user@example.test"] }
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => { "total" => 500, "invalid" => 0 } }),
                                      ScriptedTransport.reply({ "error" => "bad", "code" => "invalid_arg" }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    batches = client.each_import_batch(field_names: ["email"], data: rows)

    assert_empty transport.requests
    error = assert_raises(Unisender::BatchError) { batches.to_a }
    assert_equal [500...501, [{ "total" => 500, "invalid" => 0 }]],
                 [error.failed_range, error.completed_responses.map(&:as_json)]
  end

  def test_event_batches_stop_after_partial_acceptance
    events = Array.new(26) { { name: "sale", email: "user@example.test" } }
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "success" => true }),
                                      ScriptedTransport.reply({ "code" => "invalid_params" }, status: 400))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    error = assert_raises(Unisender::BatchError) { client.track_events_in_batches(events:).to_a }

    assert_equal 25...26, error.failed_range
    assert_equal [true, 2], [error.error.possibly_partially_accepted?, transport.requests.size]
  end

  def test_waits_for_export_completion_with_a_bounded_poll_interval
    time = 0.0
    replies = [{ "status" => "new" }, { "status" => "processing" },
               { "status" => "completed", "file_to_download" => "https://example.test/export" }]
    transport = ScriptedTransport.new(*replies.map { |result| ScriptedTransport.reply({ "result" => result }) })
    client = Unisender::Client.new(api_key: "test-key", transport:)
    result = client.wait_for_task(task_uuid: "task", interval: 2, timeout: 10,
                                  clock: -> { time }, sleeper: ->(delay) { time += delay })

    assert_equal "https://example.test/export", result.result["file_to_download"]
    assert_equal 4, time
    assert_equal 3, transport.requests.size
  end
end
