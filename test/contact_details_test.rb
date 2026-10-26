# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class ContactDetailsTest < Minitest::Test
  def test_contact_details_have_stable_readers
    data = { "email" => { "email" => "a@example.test", "rating" => 4.1, "added_at" => "2026-01-01" },
             "phone" => { "phone" => "123", "status" => "active", "availability" => "available" },
             "lists" => [{ "id" => 1, "status" => "active", "added_at" => "2026-01-01" }],
             "fields" => { "Name" => "Example" } }
    contact = Unisender::Contact.new(data)

    assert_equal ["a@example.test", "123", 4.1], [contact.email_address, contact.phone_number, contact.email.rating]
    membership = contact.lists.first

    assert_equal [1, "active", "2026-01-01"], [membership.id, membership.status, membership.added_at]
    assert_equal "Example", contact.fields["Name"]
  end

  def test_response_forwards_optional_details
    contact = Unisender::Contact.new({ "email" => "a@example.test", "phone" => "123", "lists" => [], "fields" => {} })
    response = Unisender::ContactResponse.new(data: {}, status: 200, headers: {}, result: contact)

    assert_equal ["a@example.test", "123", "123", []],
                 [response.email_address, response.phone_number, response.phone, response.lists]
    assert_empty response.fields.to_h
  end

  def test_absent_details_are_unknown
    contact = Unisender::Contact.new({})

    assert_equal [nil, nil, nil, nil], [contact.email_address, contact.phone_number, contact.lists, contact.fields]
  end

  def test_invalid_detail_shapes_are_rejected
    assert_raises(Unisender::InvalidResponseError) { Unisender::Contact.new({ "phone" => 1 }) }
    assert_raises(Unisender::InvalidResponseError) { Unisender::Contact.new({ "fields" => [] }) }
  end
end
