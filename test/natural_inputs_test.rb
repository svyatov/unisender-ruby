# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class NaturalInputsTest < Minitest::Test
  def test_count_filters_reject_invalid_types
    client = Unisender::Client.new(api_key: "test")
    assert_raises(Unisender::ValidationError) { client.get_contact_count(list_id: 1, tag_id: true) }
    assert_raises(Unisender::ValidationError) { client.get_contact_count(list_id: 1, search: false) }
    assert_raises(Unisender::ValidationError) { client.get_contact_count(list_id: 1, search: 123) }
  end

  def test_invalid_fields_have_operation_context
    client = Unisender::Client.new(api_key: "test")
    error = assert_raises(Unisender::ValidationError) { client.subscribe(list_ids: [1], fields: []) }
    assert_equal "subscribe", error.operation
  end

  def test_flags_fail_before_a_request
    transport = Unisender::Testing::Transport.new
    client = Unisender::Client.new(api_key: "test", transport:)
    error = assert_raises(Unisender::ValidationError) do
      client.get_contact(email: "a@example.test", include_lists: 2)
    end

    assert_equal ["include_lists", :invalid_flag, "getContact"], [error.field, error.code, error.operation]
    assert_empty transport.requests
  end

  def test_template_and_note_choices_accept_symbols
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] })
    transport.enqueue(data: { "result" => [] })
    client = Unisender::Client.new(api_key: "test", transport:)
    client.get_templates(type: :system)
    client.get_subscriber_notes(subscriber_id: 1, order_by: :created_at, order_type: :desc)

    assert_equal "system", transport.requests.first.form["type"]
    assert_equal %w[created_at DESC], transport.requests.last.form.values_at("order_by", "order_type")
  end

  def test_invalid_choices_are_structured
    client = Unisender::Client.new(api_key: "test")
    error = assert_raises(Unisender::ValidationError) { client.get_templates(type: :unknown) }

    assert_equal ["type", :invalid_choice, "getTemplates"], [error.field, error.code, error.operation]
  end

  def test_contact_selector_encodes_wire_values
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] })
    client = Unisender::Client.new(api_key: "test", transport:)
    client.unsubscribe(email: "a@example.test", list_ids: [1, 2])

    assert_equal ["email", "a@example.test", "1,2"],
                 transport.requests.first.form.values_at("contact_type", "contact", "list_ids")
  end

  def test_count_filters_encode_wire_values
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "count" => "2" } })
    client = Unisender::Client.new(api_key: "test", transport:)
    result = client.get_contact_count(list_id: 1, contact_type: :email, search: "example", tag_id: 2)

    assert_equal %w[address example 2],
                 transport.requests.first.form.values_at("params[type]", "params[search]", "params[tagId]")
    assert_equal 2, result.count
  end

  def test_contact_selectors_require_scope_and_reject_conflicts
    client = Unisender::Client.new(api_key: "test")

    assert_raises(Unisender::ValidationError) { client.exclude(email: "a@example.test") }
    assert_raises(Unisender::ValidationError) { client.exclude(email: "a", phone: "b", list_ids: [1]) }
    assert_raises(Unisender::ValidationError) { client.exclude(contact_type: "email", contact: "a", email: "b") }
  end

  def test_phone_selector_is_symmetric
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] })
    Unisender::Client.new(api_key: "test", transport:).exclude(phone: "123", list_ids: [1])

    assert_equal %w[phone 123], transport.requests.first.form.values_at("contact_type", "contact")
  end

  def test_convenience_contact_must_be_nonempty_text
    client = Unisender::Client.new(api_key: "test")

    assert_raises(Unisender::ValidationError) { client.unsubscribe(email: false, list_ids: [1]) }
    assert_raises(Unisender::ValidationError) { client.unsubscribe(phone: "", list_ids: [1]) }
  end

  def test_count_filter_errors
    client = Unisender::Client.new(api_key: "test")

    assert_raises(Unisender::ValidationError) { client.get_contact_count(list_id: 1, params: { type: "phone" }, tag_id: 2) }
    assert_raises(Unisender::ValidationError) { client.get_contact_count(list_id: 1, search: "text") }
    assert_raises(Unisender::ValidationError) { client.get_contact_count(list_id: 1, contact_type: :other) }
  end

  def test_phone_count_filter
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "count" => "0" } })
    Unisender::Client.new(api_key: "test", transport:).get_contact_count(list_id: 1, contact_type: :phone)

    assert_equal "phone", transport.requests.first.form["params[type]"]
  end
end
