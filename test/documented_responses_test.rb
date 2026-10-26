# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class DocumentedResponsesTest < Minitest::Test
  def test_send_test_email_preserves_the_documented_top_level_message
    data = { "message" => "Test letter was sent" }
    response = client(data).send_test_email(email: "test@example.test", id: 1)

    assert_equal data, response.to_h
    assert_equal data, response.data
  end

  def test_update_field_preserves_the_documented_top_level_id
    assert_equal({ "id" => 1 }, client({ "id" => 1 }).update_field(id: 1, name: "Name").to_h)
  end

  def test_envelope_exceptions_require_the_documented_field_types
    assert_raises(Unisender::InvalidResponseError) do
      client({ "message" => 1 }).send_test_email(email: "test@example.test", id: 1)
    end
    assert_raises(Unisender::InvalidResponseError) { client({ "id" => nil }).update_field(id: 1, name: "Name") }
  end

  def test_bare_fields_are_not_accepted_for_other_operations
    assert_raises(Unisender::InvalidResponseError) { client({ "id" => 1 }).get_lists }
    assert_raises(Unisender::InvalidResponseError) { client({ "message" => "ok" }).get_lists }
  end

  def test_top_level_api_errors_still_take_precedence
    assert_raises(Unisender::APIError) do
      client({ "message" => "ok", "error" => "denied" }).send_test_email(email: "test@example.test", id: 1)
    end
  end

  private

  def client(data)
    Unisender::Client.new(api_key: "test-key", transport: ScriptedTransport.new(ScriptedTransport.reply(data)))
  end
end
