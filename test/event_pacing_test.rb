# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class EventPacingTest < Minitest::Test
  def test_event_budget_is_independent_and_shared_by_variants
    clock = 0.0
    limiter = Unisender::RateLimiter.new(global: [1, 2], clock: -> { clock }, sleeper: ->(delay) { clock += delay })
    transport = Unisender::Testing::Transport.new
    transport.enqueue(data: { "success" => true }).enqueue(data: { "result" => [] })
    transport.enqueue(data: { "success" => true })
    client = Unisender::Client.from_env(env: { "UNISENDER_API_KEY" => "test" }, transport:, event_rate_limiter: limiter)
    client.track_events(events: [{ name: "sale", email: "a@example.test" }])
    client.get_lists
    client.with.track_events(events: [{ name: "sale", email: "a@example.test" }])

    assert_equal [2, 3], [clock, transport.requests.size]
  end

  def test_event_limiter_observes_execution_scopes
    transport = Unisender::Testing::Transport.new.enqueue(data: { "success" => true })
    client = Unisender::Client.new(api_key: "test", transport:,
                                   event_rate_limiter: Unisender::RateLimiter.new(global: [1, 1]))
    client.with_execution(timeout: 1) do |scoped|
      scoped.track_events(events: [{ name: "sale", email: "a@example.test" }])
    end

    assert_equal 1, transport.requests.size
  end

  def test_invalid_default_containers_are_local_errors
    [nil, [], { 1 => "name" }].each do |defaults|
      assert_raises(ArgumentError) { Unisender::Client.new(api_key: "test", message_defaults: defaults) }
    end
  end
end
