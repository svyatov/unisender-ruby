# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class ConfigurationTest < Minitest::Test
  def test_environment_is_explicit_and_validated
    client = Unisender::Client.from_env(env: { "UNISENDER_API_KEY" => "test-key" })

    assert_instance_of Unisender::Client, client
    assert_raises(ArgumentError) { Unisender::Client.from_env(env: {}) }
  end

  def test_client_variants_do_not_change_the_original
    replies = Array.new(2) { ScriptedTransport.reply({ "result" => { "message_id" => 1 } }) }
    transport = ScriptedTransport.new(*replies)
    original = Unisender::Client.new(api_key: "test-key", transport:,
                                     message_defaults: { sender_name: "One", sender_email: "one@example.test" })
    variant = original.with(message_defaults: { sender_name: "Two" })
    [original, variant].each { |client| client.create_email_message(list_id: 1, subject: "News", body: "Hello") }

    assert_equal(%w[One Two], transport.requests.map do |request|
      URI.decode_www_form(request[:body]).to_h["sender_name"]
    end)
  end

  def test_explicit_nil_does_not_restore_a_sender_default
    client = Unisender::Client.new(api_key: "test-key", message_defaults: { sender_name: "One" })

    assert_raises(ArgumentError) do
      client.create_email_message(sender_name: nil, sender_email: "a@b.test", list_id: 1, subject: "News",
                                  body: "Hello")
    end
  end

  def test_transport_and_timeout_conflicts_are_rejected
    assert_raises(ArgumentError) do
      Unisender::Client.new(api_key: "test-key", transport: ScriptedTransport.new, open_timeout: 2)
    end
  end

  def test_retry_options_and_variants_accept_explicit_values
    client = Unisender::Client.new(api_key: "test-key", open_timeout: 2, read_timeout: 3, write_timeout: 4,
                                   max_retries: 1, max_elapsed: 30)
    variant = client.with(transport: ScriptedTransport.new, retry_policy: Unisender::RetryPolicy.new)

    assert_instance_of Unisender::Client, variant
    assert_instance_of Unisender::Client, variant.with(open_timeout: 4, max_retries: 2)
    assert_raises(ArgumentError) { client.with(api_key: nil) }
  end

  def test_invalid_defaults_and_conflicts_fail_locally
    [{ unknown: "value" }, { sender_name: 1 }, { sender_name: "a", "sender_name" => "b" }].each do |defaults|
      assert_raises(ArgumentError) { Unisender::Client.new(api_key: "test-key", message_defaults: defaults) }
    end
    assert_raises(ArgumentError) do
      Unisender::Client.new(api_key: "test-key", retry_policy: Unisender::RetryPolicy.new, max_retries: 1)
    end
  end

  def test_nil_defaults_remove_inherited_values
    client = Unisender::Client.new(api_key: "test-key", message_defaults: { sender_name: "One" })
    variant = client.with(message_defaults: { sender_name: nil })

    assert_raises(ArgumentError) do
      variant.create_email_message(sender_email: "a@b.test", list_id: 1, subject: "News", body: "Hello")
    end
    assert_raises(ArgumentError) { client.with(message_defaults: "bad") }
    refute_includes Unisender::Configuration.new(api_key: "private-key").inspect, "private-key"
  end
end
