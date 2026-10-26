# frozen_string_literal: true

require "test_helper"

class DomainRecordsTest < Minitest::Test
  def test_contact_email_has_typed_details
    contact = Unisender::Contact.new({ "email" => { "email" => "a@b.test", "status" => "active",
                                                    "availability" => "available" } })
    response = Unisender::ContactResponse.new(data: {}, status: 200, headers: {}, result: contact)

    assert_equal ["a@b.test", "active", "available"],
                 [response.email.email, response.email.status, response.email.availability]
    assert_nil Unisender::Contact.new({}).email
    assert_raises(Unisender::InvalidResponseError) { Unisender::Contact.new({ "email" => 1 }) }
  end

  def test_sender_domain_names_keep_wire_keys
    group = Unisender::SenderDomainGroup.new({ "status" => "success", "domains" => [
                                               { "Domain" => "example.test", "Status" => "active", "key" => "key" }
                                             ] })
    domain = group.domains.first

    assert_equal ["success", "example.test", "active", "key"], [group.status, domain.domain, domain.status, domain.key]
    assert_equal "example.test", domain["Domain"]
  end

  def test_campaign_counters_have_direct_readers
    fields = %w[total sent delivered read_unique read_all clicked_unique clicked_all unsubscribed spam]
    result = Unisender::CampaignStats.new(fields.to_h { |name| [name, 1] })
    response = Unisender::CampaignStatsResponse.new(data: {}, status: 200, headers: {}, result:)

    assert_equal([1] * fields.size, fields.map { |field| response.public_send(field) })
    assert_nil Unisender::CampaignStats.new({}).total
  end

  def test_sms_receipt_exposes_price_and_identifier
    result = Unisender::SmsReceipt.new({ "sms_id" => 1, "price" => 1.5, "currency" => "RUB" })

    assert_equal [1, 1.5, "RUB"], [result.sms_id, result.price, result.currency]
    assert_nil Unisender::SmsReceipt.new({ "sms_id" => 1 }).price
    assert_raises(Unisender::InvalidResponseError) { Unisender::SmsReceipt.new({ "sms_id" => 1, "price" => "bad" }) }
  end

  def test_contact_field_ids_remain_dynamic
    result = Unisender::ContactFields.new({ "fieldValues" => { "12" => "Name" } })
    response = Unisender::ContactFieldsResponse.new(data: {}, status: 200, headers: {}, result:)

    assert_equal "Name", response.field_values["12"]
    assert_raises(Unisender::InvalidResponseError) { Unisender::ContactFields.new({}) }
  end

  def test_delivery_identifier_is_optional
    delivery = Unisender::EmailDelivery.new({ "id" => "id", "status" => "ok_delivered" })

    assert_equal %w[id ok_delivered], [delivery.id, delivery.status]
    assert_nil Unisender::EmailDelivery.new({}).id
  end
end
