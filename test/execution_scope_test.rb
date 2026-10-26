# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class ExecutionScopeTest < Minitest::Test
  def test_cancelled_scope_does_not_request_or_close_parent
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] })
    client = Unisender::Client.new(api_key: "test", transport:)
    token = Unisender::CancellationToken.new
    token.cancel
    client.with_execution(cancellation: token) do |scoped|
      assert_raises(Unisender::CancelledError) { scoped.get_lists }
      scoped.close
    end
    client.get_lists
    transport.verify!
  end

  def test_deadline_covers_callback_and_scope_expires_after_block
    client = Unisender::Client.new(api_key: "test")
    saved = nil
    client.with_execution(timeout: 0.001) do |scoped|
      saved = scoped
      sleep(0.002)
      assert_raises(Unisender::DeadlineExceededError) { scoped.get_lists }
    end
    assert_raises(Unisender::ClientClosedError) { saved.get_lists }
  end

  def test_nested_scopes_respect_parent_cancellation
    token = Unisender::CancellationToken.new
    client = Unisender::Client.new(api_key: "test")
    client.with_execution(cancellation: token) do |outer|
      outer.with_execution(timeout: 60) do |inner|
        token.cancel
        assert_raises(Unisender::CancelledError) { inner.get_lists }
      end
    end
  end

  def test_scope_wait_splits_sleep_and_emits_safe_metadata
    now = 0.0
    events = []
    context = Unisender::ExecutionContext.new(timeout: 1, clock: -> { now }, instrumentation: events.method(:push))
    error = assert_raises(Unisender::DeadlineExceededError) do
      context.wait(2, :poll_wait, "async/getTaskResult", ->(delay) { now += delay })
    end
    assert_equal :deadline_exceeded, error.category
    assert_equal %i[poll_wait failure], [events.first.kind, events.first.outcome]
  end

  def test_scope_reports_workflow_and_survives_observer_errors
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] })
    client = Unisender::Client.new(api_key: "test", transport:)
    result = client.with_execution(instrumentation: ->(_) { raise "observer" }) { |scoped| scoped.get_lists.size }

    assert_equal 0, result
  end

  def test_invalid_scope_timeout
    assert_raises(ArgumentError) { Unisender::ExecutionContext.new(timeout: 0) }
  end

  def test_cancel_category_and_configured_child_share_the_scope
    token = Unisender::CancellationToken.new
    client = Unisender::Client.new(api_key: "test")
    client.with_execution(cancellation: token) do |scoped|
      child = scoped.with(language: :ru)
      token.cancel
      error = assert_raises(Unisender::CancelledError) { child.get_lists }
      assert_equal :cancelled, error.category
    end
  end

  # Shared fake time proves both waiting paths use the same context.
  # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
  def test_retry_and_rate_waits_observe_the_scope
    now = 0.0
    events = []
    clock = -> { now }
    sleeper = ->(delay) { now += delay }
    context = Unisender::ExecutionContext.new(clock:, instrumentation: events.method(:push))
    limiter = Unisender::RateLimiter.new(global: [1, 0.1], clock:, sleeper:)
    2.times { limiter.acquire("getLists", execution: context) }
    policy = Unisender::RetryPolicy.new(max_retries: 1, clock:, sleeper:, random: -> { 0.0 })
    calls = 0
    policy.call("getLists", execution: context) do
      calls += 1
      raise Unisender::TimeoutError.new("timeout", retryable: true) if calls == 1
    end

    assert_equal %i[rate_limit_wait retry_wait], events.map(&:kind)
  end

  def test_polling_wait_uses_client_scope
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "status" => "new" } })
    transport.enqueue(data: { "result" => { "status" => "completed" } })
    client = Unisender::Client.new(api_key: "test", transport:)
    events = []
    result = client.with_execution(instrumentation: events.method(:push)) do |scoped|
      scoped.wait_for_task(task_uuid: "task", interval: 0.001)
    end

    assert_predicate result, :completed?
    assert_equal %i[poll_wait workflow], events.map(&:kind)
  end

  def test_cancellation_between_batches_preserves_completed_work
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "invalid" => 0 } })
    client = Unisender::Client.new(api_key: "test", transport:)
    token = Unisender::CancellationToken.new
    client.with_execution(cancellation: token) do |scoped|
      error = assert_raises(Unisender::BatchError) do
        scoped.each_import_batch(records: [{ email: "a" }, { email: "b" }], batch_size: 1) { token.cancel }
      end
      assert_equal [1, 1...1, :cancelled], [error.report.completed_batches, error.failed_range, error.category]
    end
  end
end
