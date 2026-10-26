# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class IteratorContractsTest < Minitest::Test
  METHODS = {
    "get_campaigns" => "each_campaign", "get_messages" => "each_message",
    "list_messages" => "each_message_summary", "get_templates" => "each_template",
    "list_templates" => "each_template_summary", "get_sender_domain_list" => "each_sender_domain_group",
    "get_subscriber_notes" => "each_subscriber_note"
  }.freeze

  METHODS.each do |operation, iterator|
    define_method("test_#{iterator}_preserves_items") do
      fixture = JSON.parse(File.read(File.join(__dir__, "fixtures/operations.json")))
                    .find { |item| item.fetch("name") == operation }
      transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => fixture.fetch("result") }))
      client = Unisender::Client.new(api_key: "test-key", transport:)
      arguments = fixture.fetch("args").transform_keys(&:to_sym)
      result = client.public_send(iterator, **arguments).to_a

      assert_equal fixture.fetch("result"), result
      assert_equal 1, transport.requests.size
    end
  end

  def test_page_bound_identifies_the_next_unread_offset
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => [{ "id" => 1 }] }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    error = assert_raises(Unisender::PaginationError) { client.each_template(page_size: 1, max_pages: 1).to_a }

    assert_equal [1, 1], [error.next_offset, error.completed_pages]
  end

  def test_request_failure_carries_the_resume_offset
    transport = ScriptedTransport.new(ScriptedTransport.reply({}, status: 503))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    error = assert_raises(Unisender::HTTPError) { client.each_template(offset: 20).to_a }

    assert_equal [20, 0], [error.next_offset, error.completed_pages]
  end

  def test_item_iterator_accepts_a_block
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => [{ "id" => 1 }] }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    ids = []
    client.each_template { |template| ids << template.id }

    assert_equal [1], ids
    assert_equal 1, transport.requests.size
  end
end
