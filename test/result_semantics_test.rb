# frozen_string_literal: true

require "test_helper"
require "unisender/testing"
# rubocop:disable-next Lint/RedundantRequireStatement -- Required on supported Ruby versions before 4.0.
require "set"

class ResultSemanticsTest < Minitest::Test
  def test_equal_records_work_in_sets_and_hashes
    first = Unisender::List.new({ "id" => 1, "title" => "News" })
    second = Unisender::List.new({ "id" => 1, "title" => "News" })

    assert_equal 1, Set.new([first, second]).size
    assert_equal :found, { first => :found }[second]
    assert_equal first, second
  end

  def test_record_equality_preserves_class_and_numeric_semantics
    first = Unisender::Record.new({ "value" => 1 })
    float = Unisender::Record.new({ "value" => 1.0 })
    list = Unisender::List.new({ "id" => 1, "title" => "News" })

    assert_equal first, float
    refute first.eql?(float)
    refute_equal list, Unisender::Record.new(list.to_h)
  end

  def test_records_do_not_compare_equal_to_plain_values
    record = Unisender::Record.new({ "id" => 1 })

    refute_equal record, record.to_h
    refute record.eql?(record.to_h)
    refute record.eql?(Unisender::List.new({ "id" => 1, "title" => "News" }))
  end

  def test_object_response_forwards_lookup
    record = Unisender::Record.new({ "id" => 1 })
    response = Unisender::ObjectResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert response.key?(:id)
    assert_equal ["id"], response.keys
    assert_equal [1], response.values
  end

  def test_failed_task_wait_preserves_context_without_network
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "status" => "failed" } })
    task = Unisender::Client.new(api_key: "test", transport:).get_task_result(task_uuid: "task")
    observed = []
    error = assert_raises(Unisender::TaskFailedError) { task.wait { |state| observed << state } }

    assert_equal [task, "task", [task], 1], [error.response, error.task_uuid, observed, transport.requests.size]
    assert_raises(Unisender::TaskFailedError) { task.wait }
  end
end
