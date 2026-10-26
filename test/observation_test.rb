# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class ObservationTest < Minitest::Test
  def test_events_contain_metadata_without_credentials_or_contact_data
    events = []
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => [] }))
    client = Unisender::Client.new(api_key: "private-key", transport:, instrumentation: ->(event) { events << event })
    client.get_lists

    event = events.first

    assert_equal ["getLists", 1, 200, :success, nil],
                 [event.operation, event.attempt, event.http_status, event.outcome, event.error_category]
    refute_includes events.inspect, "private-key"
  end

  def test_event_duration_uses_a_monotonic_clock
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    event = Unisender::Observation.event("getLists", 1, started, nil, nil)

    assert_operator event.duration, :>=, 0
  end

  def test_callback_failure_does_not_change_request_success
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => [] }))
    client = Unisender::Client.new(api_key: "test-key", transport:,
                                   instrumentation: ->(_event) { raise "Callback failed" })

    assert_empty client.get_lists
    assert_equal 1, transport.requests.size
  end

  def test_unknown_operation_names_are_redacted
    events = []
    transport = ScriptedTransport.new(Unisender::TimeoutError.new("Timed out"))
    client = Unisender::Client.new(api_key: "test-key", transport:, instrumentation: ->(event) { events << event })

    assert_raises(Unisender::TimeoutError) { client.request("privateMethod") }
    assert_equal ["request", nil, :failure, :timeout],
                 [events.first.operation, events.first.http_status, events.first.outcome, events.first.error_category]
  end

  def test_unexpected_transport_failure_is_observed_and_preserved
    events = []
    transport = ScriptedTransport.new(RuntimeError.new("private data"))
    client = Unisender::Client.new(api_key: "test-key", transport:, instrumentation: ->(event) { events << event })

    assert_raises(RuntimeError) { client.get_lists }
    assert_equal :unexpected, events.first.error_category
    refute_includes events.inspect, "private data"
  end

  def test_retries_have_distinct_attempt_numbers
    events = []
    policy = Unisender::RetryPolicy.new(max_retries: 1, sleeper: ->(_delay) {}, random: -> { 0.0 })
    transport = ScriptedTransport.new(ScriptedTransport.reply({}, status: 503),
                                      ScriptedTransport.reply({ "result" => [] }))
    client = Unisender::Client.new(api_key: "test-key", transport:, retry_policy: policy,
                                   instrumentation: ->(event) { events << event })
    client.get_lists

    assert_equal [1, 2], events.map(&:attempt)
    assert_equal %i[failure success], events.map(&:outcome)
  end
end
