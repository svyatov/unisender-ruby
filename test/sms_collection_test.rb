# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class SmsCollectionTest < Minitest::Test
  def test_single_sms_returns_a_collection_with_the_raw_envelope
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "sms_id" => 1 } })
    response = Unisender::Client.new(api_key: "test", transport:).send_sms(phone: "123", sender: "News", text: "Hi")

    assert_equal [1], response.map(&:sms_id)
    assert_equal({ "sms_id" => 1 }, response.data["result"])
  end

  def test_multiple_sms_accept_array_input
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [{ "sms_id" => 1 }, { "sms_id" => 2 }] })
    client = Unisender::Client.new(api_key: "test", transport:)
    response = client.send_sms(phone: %w[123 456], sender: "News", text: "Hi")

    assert_equal [1, 2], response.map(&:sms_id)
    assert_equal "123,456", transport.requests.first.form["phone"]
  end

  def test_empty_or_excess_recipients_fail_before_networking
    client = Unisender::Client.new(api_key: "test", transport: Unisender::Testing::Transport.new)

    [[], [" "], "123,", Array.new(151, "123")].each do |phone|
      assert_raises(Unisender::ValidationError) { client.send_sms(phone:, sender: "News", text: "Hi") }
    end
    assert_raises(Unisender::ValidationError) { Unisender::SmsInputs.phone(nil) }
  end
end
