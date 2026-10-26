# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class RateLimiterTest < Minitest::Test
  def setup
    @time = 0.0
    @sleeps = []
  end

  def test_global_and_method_windows_are_combined
    limiter = limiter_for([2, 10], { "sendEmail" => [1, 20] })
    limiter.acquire("sendEmail")
    limiter.acquire("getLists")
    limiter.acquire("sendEmail")

    assert_equal [20.0], @sleeps
  end

  def test_events_do_not_consume_the_marketing_budget
    client = client_for({ "result" => [] }, { "success" => true }, { "result" => [] })
    client.get_lists
    client.track_events(events: [{ name: "sale", email: "a@b.test" }])
    client.get_lists

    assert_equal [1.0], @sleeps
  end

  def test_retries_consume_budget
    policy = Unisender::RetryPolicy.new(max_retries: 1, sleeper: ->(_delay) {})
    client = client_for({ "result" => [] }, retry_policy: policy, failure: true)
    client.get_lists

    assert_equal [1.0], @sleeps
  end

  def test_invalid_budgets_and_the_documented_preset
    [[0, 1], [1, 0], [1, Float::INFINITY]].each do |budget|
      assert_raises(ArgumentError) { Unisender::RateLimiter.new(global: budget) }
    end
    limiter = Unisender::RateLimiter.unisender
    limiter.acquire("getLists")

    assert_equal "#<Unisender::RateLimiter>", limiter.inspect
  end

  def test_client_close_does_not_close_an_injected_transport
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] })
    client = Unisender::Client.new(api_key: "test-key", transport:)
    client.close
    client.close

    assert_raises(Unisender::ClientClosedError) { client.get_lists }
    assert_equal 200, transport.post(URI("https://api.unisender.com/en/api/getLists"), headers: {}, body: "").status
  end

  def test_closing_a_default_client_and_using_the_default_sleeper
    client = Unisender::Client.new(api_key: "test-key")
    client.close
    limiter = Unisender::RateLimiter.new(global: [1, 0.001])
    2.times { limiter.acquire("getLists") }

    assert_raises(Unisender::ClientClosedError) { client.get_lists }
  end

  def test_persistent_configuration_and_conflicting_transport
    client = Unisender::Client.new(api_key: "test-key", persistent: true)
    client.close

    assert_raises(Unisender::ClientClosedError) { client.get_lists }
    assert_raises(ArgumentError) do
      Unisender::Client.new(api_key: "test-key", transport: Unisender::Transport.new, persistent: true)
    end
  end

  private

  def limiter_for(global, methods = {})
    Unisender::RateLimiter.new(global:, methods:, clock: -> { @time }, sleeper: lambda { |delay|
      @sleeps << delay
      @time += delay
    })
  end

  def client_for(*replies, retry_policy: nil, failure: false)
    transport = Unisender::Testing::Transport.new
    transport.enqueue(data: {}, http_status: 503) if failure
    replies.each { |reply| transport.enqueue(data: reply) }
    Unisender::Client.new(api_key: "test-key", transport:, rate_limiter: limiter_for([1, 1]), retry_policy:)
  end
end
