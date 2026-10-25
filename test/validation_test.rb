# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class ValidationTest < Minitest::Test
  def setup
    replies = Array.new(20) { ScriptedTransport.reply }
    @transport = ScriptedTransport.new(*replies)
    @client = Unisender::Client.new(api_key: "test-key", transport: @transport)
  end

  def test_requires_structurally_valid_import_rows
    [[], [%w[one extra]], ["not a row"], Array.new(501) { ["a@example.test"] }].each do |rows|
      assert_raises(ArgumentError) { @client.import_contacts(field_names: ["email"], data: rows) }
    end
    [["Name"], %w[email email], [1]].each do |fields|
      assert_raises(ArgumentError) { @client.import_contacts(field_names: fields, data: [["value"]]) }
    end
    assert_empty @transport.requests
  end

  def test_requires_content_or_a_template_for_email_creation
    args = { sender_name: "Sender", sender_email: "sender@example.test", list_id: 1 }

    assert_raises(ArgumentError) { @client.create_email_message(**args) }
    assert_raises(ArgumentError) { @client.create_email_message(**args, subject: "News") }
    @client.create_email_message(**args, template_id: 1)
    @client.create_email_message(**args, system_template_id: 1)

    assert_equal 2, @transport.requests.size
  end

  def test_rejects_conflicting_campaign_recipient_sources
    assert_raises(ArgumentError) do
      @client.create_campaign(message_id: 1, contacts: "a@example.test", contacts_url: "https://example.test/contacts")
    end
    assert_raises(ArgumentError) { @client.get_template }
    assert_empty @transport.requests
  end

  def test_required_values_and_comma_separated_lists
    [nil, "", [], {}].each do |title|
      assert_raises(ArgumentError) { @client.create_list(title:) }
    end
    assert_raises(ArgumentError) { @client.subscribe(list_ids: [[1]], fields: { email: "a@example.test" }) }
    @client.subscribe(list_ids: [1, "2"], fields: { email: "a@example.test" }, tags: %w[news updates])
    body = URI.decode_www_form(@transport.requests.last[:body]).to_h

    assert_equal ["1,2", "news,updates"], [body["list_ids"], body["tags"]]
  end
end
