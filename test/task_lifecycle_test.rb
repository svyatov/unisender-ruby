# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class TaskLifecycleTest < Minitest::Test
  def test_completed_handle_wait_observes_itself_without_network
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "status" => "completed" } })
    task = Unisender::Client.new(api_key: "test", transport:).get_task_result(task_uuid: "task")
    seen = []

    assert_same(task, task.wait { |state| seen << state })
    assert_equal [task], seen
    assert_equal 1, transport.requests.size
  end

  def test_task_predicates_describe_only_task_state
    client = Unisender::Client.new(api_key: "test")
    response = Unisender::TaskResultResponse.new(data: {}, status: 200, headers: {},
                                                 result: Unisender::TaskResult.new({ "status" => "processing" }))
    task = Unisender::TaskResponse.new(response, client:, task_uuid: "task")

    assert_equal [false, false, true], [task.completed?, task.failed?, task.pending?]
  end

  def test_scoped_client_closes_after_failure
    scoped = nil
    assert_raises(RuntimeError) do
      Unisender::Client.open(api_key: "test") do |client|
        scoped = client
        raise "stop"
      end
    end

    assert_raises(Unisender::ClientClosedError) { scoped.get_lists }
  end

  def test_open_returns_the_block_result_and_requires_a_block
    assert_equal :done, Unisender::Client.open(api_key: "test") { :done }
    assert_raises(ArgumentError) { Unisender::Client.open(api_key: "test") }
  end

  def test_completed_wait_does_not_require_a_callback
    response = Unisender::TaskResultResponse.new(data: {}, status: 200, headers: {},
                                                 result: Unisender::TaskResult.new({ "status" => "completed" }))
    task = Unisender::TaskResponse.new(response, client: Unisender::Client.new(api_key: "test"), task_uuid: "task")

    assert_same task, task.wait
    assert_equal [true, false, false], [task.completed?, task.failed?, task.pending?]
  end
end
