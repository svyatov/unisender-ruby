# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class DxExecutionTest < Minitest::Test
  def test_batch_command_executes_before_returning
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => { "invalid" => 0 } }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    report = client.import_contacts_in_batches(field_names: ["email"], data: [["a@b.test"]])

    assert_equal 1, transport.requests.size
    assert_predicate report, :complete?
    assert_equal 1, report.to_a.size
  end

  def test_explicit_batch_iterator_remains_lazy
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "success" => true }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    batches = client.each_event_batch(events: [{ name: "sale", email: "a@b.test" }])

    assert_empty transport.requests
    assert_equal 1, batches.to_a.size
  end

  def test_page_iteration_uses_the_fetched_page
    transport = ScriptedTransport.new(
      ScriptedTransport.reply({ "result" => [{ "id" => 1 }] }),
      ScriptedTransport.reply({ "result" => [] })
    )
    client = Unisender::Client.new(api_key: "test-key", transport:)
    page = client.get_templates(limit: 1)

    assert_equal [1], page.auto_each.map(&:id)
    assert_equal 2, transport.requests.size
  end

  def test_report_enumeration_has_no_network_effects
    report = Unisender::BatchReport.new([])

    assert_equal 0, report.completed_batches
    assert_instance_of Enumerator, report.each
  end

  def test_item_iterator_is_lazy_and_validates_immediately
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => [{ "id" => 1 }] }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    items = client.each_template

    assert_empty transport.requests
    assert_equal [1], items.take(1).map(&:id)
    assert_raises(ArgumentError) { client.each_page(:get_templates, page_size: 0) }
  end
end
