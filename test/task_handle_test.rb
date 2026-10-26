# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class TaskHandleTest < Minitest::Test
  def test_waiting_is_explicit_and_reports_progress
    transport = ScriptedTransport.new(
      ScriptedTransport.reply({ "result" => { "task_uuid" => "task", "status" => "new" } }),
      ScriptedTransport.reply({ "result" => { "status" => "completed", "file_to_download" => "https://example.test" } })
    )
    client = Unisender::Client.new(api_key: "test-key", transport:)
    task = client.export_contacts
    states = []

    completed = task.wait { |state| states << state.status }

    assert_equal ["task", ["completed"]], [completed.task_uuid, states]
    assert_equal 2, transport.requests.size
  end

  def test_timeout_preserves_the_task_and_last_response
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => { "status" => "processing" } }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    time = 0.0
    error = assert_raises(Unisender::TaskTimeoutError) do
      client.wait_for_task(task_uuid: "task", timeout: 1, clock: -> { time }, sleeper: ->(delay) { time += delay })
    end

    assert_equal %w[task processing], [error.task_uuid, error.response.status]
  end

  def test_missing_task_identifier_is_malformed
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => { "status" => "new" } }))
    client = Unisender::Client.new(api_key: "test-key", transport:)

    assert_raises(Unisender::InvalidResponseError) { client.export_contacts }
  end

  def test_unknown_task_state_is_distinct_from_failure
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => { "status" => "unknown" } }))
    client = Unisender::Client.new(api_key: "test-key", transport:)

    assert_raises(Unisender::UnknownTaskStateError) { client.wait_for_task(task_uuid: "task") }
  end
end
