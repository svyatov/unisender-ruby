# frozen_string_literal: true

require "test_helper"
require "stringio"
require "unisender/testing"
require_relative "support/scripted_transport"

class TaskHandleTest < Minitest::Test
  def test_download_requires_a_completed_task_and_a_url
    transport = Unisender::Testing::Transport.new
    %w[new completed].each { |status| transport.enqueue(data: { "result" => { "status" => status } }) }
    client = Unisender::Client.new(api_key: "test-key", transport:)

    assert_raises(Unisender::TaskError) { client.get_task_result(task_uuid: "task").download_to(StringIO.new, max_bytes: 10) }
    assert_raises(Unisender::InvalidResponseError) do
      client.get_task_result(task_uuid: "task").download_to(StringIO.new, max_bytes: 10)
    end
  end

  def test_download_uses_the_task_url_and_callers_destination
    data = { "result" => { "status" => "completed", "file_to_download" => "https://files.example.test/export" } }
    transport = Unisender::Testing::Transport.new.enqueue(data:)
    task = Unisender::Client.new(api_key: "test-key", transport:).get_task_result(task_uuid: "task")
    downloader = Object.new
    downloader.define_singleton_method(:download) { |url, io, max_bytes:| [url, io, max_bytes] }
    io = StringIO.new

    assert_equal [task.file_to_download, io, 10], task.download_to(io, max_bytes: 10, downloader:)
  end

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
