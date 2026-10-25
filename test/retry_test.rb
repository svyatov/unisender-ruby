# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class RetryTest < Minitest::Test
  def setup
    @time = 0.0
    @sleeps = []
    @policy = Unisender::RetryPolicy.new(max_retries: 2, clock: -> { @time }, random: -> { 0.0 },
                                         sleeper: lambda { |delay|
                                           @sleeps << delay
                                           @time += delay
                                         })
  end

  def test_retries_transient_reads_with_exponential_backoff
    transport = ScriptedTransport.new(ScriptedTransport.reply({}, status: 503),
                                      ScriptedTransport.reply({ "error" => "busy", "code" => "retry_later" }),
                                      ScriptedTransport.reply({ "result" => [1] }))
    client = Unisender::Client.new(api_key: "test-key", transport:, retry_policy: @policy)

    assert_equal [1], client.get_lists.result
    assert_equal [1.0, 2.0], @sleeps
    assert_equal 3, transport.requests.size
  end

  def test_never_retries_mutations_unknown_methods_or_permanent_errors
    %w[sendEmail importContacts async/exportContacts unknown getLists].each do |method|
      transport = ScriptedTransport.new(ScriptedTransport.reply({ "error" => "no", "code" => "invalid_arg" }))
      client = Unisender::Client.new(api_key: "test-key", transport:, retry_policy: @policy)

      assert_raises(Unisender::APIError) { client.request(method) }
      assert_equal 1, transport.requests.size
    end
    assert_empty @sleeps
  end

  def test_honors_retry_after_and_stops_at_retry_budget
    replies = Array.new(3) do
      ScriptedTransport.reply({}, status: 429, headers: { "retry-after" => "20" })
    end
    transport = ScriptedTransport.new(*replies)
    client = Unisender::Client.new(api_key: "test-key", transport:, retry_policy: @policy)

    assert_raises(Unisender::HTTPError) { client.get_lists }
    assert_equal [20.0, 20.0], @sleeps
    assert_equal 3, transport.requests.size
  end

  def test_default_policy_does_not_retry
    transport = ScriptedTransport.new(ScriptedTransport.reply({}, status: 503))

    assert_raises(Unisender::HTTPError) { Unisender::Client.new(api_key: "test-key", transport:).get_lists }
    assert_equal 1, transport.requests.size
  end
end
