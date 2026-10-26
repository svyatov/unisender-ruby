# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class QaRegressionsTest < Minitest::Test
  def test_stream_failures_retain_accepted_imports
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "total" => 1, "invalid" => 0 } })
    client = Unisender::Client.new(api_key: "test-key", transport:)
    source = Enumerator.new do |rows|
      rows << ["a@example.test"]
      raise IOError, "source unavailable"
    end
    error = assert_raises(Unisender::BatchError) do
      client.import_contacts_in_batches(field_names: ["email"], data: source, batch_size: 1)
    end

    assert_equal [1, 1...1, IOError], [error.completed_responses.size, error.failed_range, error.error.class]
  end

  def test_stream_failures_retain_accepted_events
    transport = Unisender::Testing::Transport.new.enqueue(data: { "success" => true })
    client = Unisender::Client.new(api_key: "test-key", transport:)
    source = Enumerator.new do |events|
      events << { name: "sale", email: "a@example.test" }
      raise "source unavailable"
    end
    error = assert_raises(Unisender::BatchError) { client.track_events_in_batches(events: source, batch_size: 1) }

    assert_equal [1, RuntimeError], [error.completed_responses.size, error.error.class]
  end

  def test_polling_failure_keeps_task_and_last_response
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "status" => "processing" } })
    transport.enqueue(data: {}, http_status: 503)
    client = Unisender::Client.new(api_key: "test-key", transport:)
    error = assert_raises(Unisender::HTTPError) do
      client.wait_for_task(task_uuid: "job", sleeper: ->(_delay) {})
    end

    assert_equal ["job", "processing", 503], [error.task_uuid, error.last_response.status, error.response.http_status]
  end

  def test_first_poll_failure_has_no_previous_state
    transport = Unisender::Testing::Transport.new.enqueue_response(Unisender::TimeoutError.new("timeout"))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    error = assert_raises(Unisender::TimeoutError) { client.wait_for_task(task_uuid: "job") }

    assert_equal "job", error.task_uuid
    assert_nil error.last_response
  end

  def test_typed_failures_are_observed_once_without_retry
    %i[get_lists get_templates].each do |method|
      events = []
      transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [{ "title" => "missing id" }] })
      client = Unisender::Client.new(api_key: "test-key", transport:, max_retries: 1,
                                     instrumentation: ->(event) { events << event })

      assert_raises(Unisender::InvalidResponseError) { client.public_send(method) }
      assert_equal([[:failure, :invalid_response, 200]], events.map do |e|
        [e.outcome, e.error_category, e.http_status]
      end)
    end
  end

  def test_direct_pagination_rejects_invalid_controls_without_a_request
    transport = Unisender::Testing::Transport.new
    client = Unisender::Client.new(api_key: "test-key", transport:)

    [{ limit: 0 }, { limit: false }, { limit: 101 }, { limit: -1 }, { offset: -1 }, { offset: 0.5 }].each do |options|
      assert_raises(ArgumentError) { client.get_templates(**options) }
    end

    assert_empty transport.requests
  end

  def test_downloads_reject_special_use_addresses_before_connecting
    %w[64:ff9b::a00:1 64:ff9b:1::a00:1 100::1 2001:2::1 2002:a00:1::1 3fff::1 192.88.99.2].each do |address|
      target = Unisender::DownloadTarget.new(timeout: 1, resolver: ->(_host) { [address] })
      error = assert_raises(Unisender::DownloadError) { target.resolve("https://files.example.test") }

      assert_equal :blocked_destination, error.reason
    end
  end

  def test_downloads_allow_ordinary_public_ipv6
    target = Unisender::DownloadTarget.new(timeout: 1, resolver: ->(_host) { ["2606:4700:4700::1111"] })

    assert_equal "2606:4700:4700::1111", target.resolve("https://files.example.test").last
  end
end
