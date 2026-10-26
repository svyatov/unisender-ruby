# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class CampaignWorkflowTest < Minitest::Test
  MESSAGE = { list_id: 1, subject: "News", body: "Hello" }.freeze

  def setup
    @transport = Unisender::Testing::Transport.new
    @client = Unisender::Client.new(api_key: "test-key", transport: @transport,
                                    message_defaults: { sender_name: "Sender", sender_email: "a@b.test" })
  end

  def test_workflow_uses_the_created_message
    @transport.enqueue(data: { "result" => { "message_id" => 1 } }, operation: "createEmailMessage")
    @transport.enqueue(data: { "result" => { "campaign_id" => 2, "status" => "scheduled" } },
                       operation: "createCampaign")
    result = @client.send_campaign(message: MESSAGE)

    assert_equal [1, 2], [result.message.message_id, result.campaign.campaign_id]
    assert_equal "1", @transport.requests.last.form["message_id"]
  end

  def test_preflight_rejects_options_before_creating_a_message
    [{ unknown: 1 }, { message_id: 1 }, { contacts: [1], contacts_url: "https://example.test" }].each do |campaign|
      assert_raises(ArgumentError) { @client.send_campaign(message: MESSAGE, campaign:) }
    end
    assert_raises(ArgumentError) { @client.send_campaign(message: MESSAGE.merge(unknown: 1)) }
    assert_empty @transport.requests
  end

  def test_second_step_failure_preserves_the_message
    @transport.enqueue(data: { "result" => { "message_id" => 1 } })
    @transport.enqueue(data: { "error" => "Rejected", "code" => "invalid_arg" })
    error = assert_raises(Unisender::CampaignWorkflowError) { @client.send_campaign(message: MESSAGE) }

    assert_equal [1, Unisender::APIError, 2],
                 [error.message_response.message_id, error.error.class, @transport.requests.size]
  end

  def test_first_step_failure_remains_an_api_error
    @transport.enqueue(data: { "error" => "Rejected", "code" => "invalid_arg" })

    assert_raises(Unisender::APIError) { @client.send_campaign(message: MESSAGE) }
    assert_equal 1, @transport.requests.size
  end
end
