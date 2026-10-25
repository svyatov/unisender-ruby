# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class RetryBoundariesTest < Minitest::Test
  def test_unsafe_operations_do_not_retry_transient_failures
    %w[sendEmail subscribe async/exportContacts importContacts unknown].each do |method|
      transport = ScriptedTransport.new(ScriptedTransport.reply({}, status: 503))
      client = build_client(transport)

      assert_raises(Unisender::HTTPError) { client.request(method) }
      assert_equal 1, transport.requests.size
    end
  end

  def test_transport_retryability
    [Unisender::TimeoutError.new("timeout"),
     Unisender::TransportError.new("connection", retryable: true)].each do |error|
      transport = ScriptedTransport.new(error, ScriptedTransport.reply)

      assert_equal [], build_client(transport).get_lists.result
    end
  end

  def test_permanent_transport_and_protocol_failures
    [Unisender::TransportError.new("tls"), Unisender::InvalidResponseError.new("invalid")].each do |error|
      assert_raises(error.class) { build_client(ScriptedTransport.new(error)).get_lists }
    end
  end

  def test_long_retry_after_and_exhausted_elapsed_budget
    %w[31 60].each do |delay|
      transport = ScriptedTransport.new(ScriptedTransport.reply({}, status: 429, headers: { "retry-after" => delay }))

      assert_raises(Unisender::HTTPError) { build_client(transport).get_lists }
    end
  end

  def test_retry_after_dates_and_invalid_values
    [(Time.now - 10).httpdate, "invalid"].each do |delay|
      transport = ScriptedTransport.new(ScriptedTransport.reply({}, status: 429, headers: { "retry-after" => delay }),
                                        ScriptedTransport.reply)

      assert_equal [], build_client(transport).get_lists.result
    end
  end

  def test_expired_budget_after_sleep
    time = 0.0
    policy = Unisender::RetryPolicy.new(max_retries: 2, max_elapsed: 2, clock: -> { time },
                                        sleeper: ->(_delay) { time = 5 }, random: -> { 0.0 })
    client = Unisender::Client.new(api_key: "test-key", retry_policy: policy,
                                   transport: ScriptedTransport.new(ScriptedTransport.reply({}, status: 503)))

    assert_raises(Unisender::HTTPError) { client.get_lists }
  end

  def test_invalid_retry_configuration
    [-1, 3, "1"].each { |n| assert_raises(ArgumentError) { Unisender::RetryPolicy.new(max_retries: n) } }
    [0, Float::INFINITY, "1"].each { |n| assert_raises(ArgumentError) { Unisender::RetryPolicy.new(max_elapsed: n) } }
  end

  private

  def build_client(transport)
    policy = Unisender::RetryPolicy.new(max_retries: 2, sleeper: ->(_delay) {})
    Unisender::Client.new(api_key: "test-key", transport:, retry_policy: policy)
  end
end
