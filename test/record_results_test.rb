# frozen_string_literal: true

require "test_helper"

class RecordResultsTest < Minitest::Test
  def test_message_created_readers
    record = Unisender::MessageCreated.new({ "message_id" => 1 })
    response = Unisender::MessageCreatedResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1], %i[message_id].map { |key| record.public_send(key) })
    assert_equal([1], %i[message_id].map { |key| response.public_send(key) })
  end

  def test_subscription_readers
    record = Unisender::Subscription.new({ "person_id" => 1 })
    response = Unisender::SubscriptionResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1], %i[person_id].map { |key| record.public_send(key) })
    assert_equal([1], %i[person_id].map { |key| response.public_send(key) })
  end

  def test_campaign_created_readers
    record = Unisender::CampaignCreated.new({ "campaign_id" => 1, "status" => "scheduled" })
    response = Unisender::CampaignCreatedResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1, "scheduled"], %i[campaign_id status].map { |key| record.public_send(key) })
    assert_equal([1, "scheduled"], %i[campaign_id status].map { |key| response.public_send(key) })
  end

  def test_status_readers
    record = Unisender::Status.new({ "status" => "completed" })
    response = Unisender::StatusResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal(["completed"], %i[status].map { |key| record.public_send(key) })
    assert_equal(["completed"], %i[status].map { |key| response.public_send(key) })
  end

  def test_contact_count_readers
    record = Unisender::ContactCount.new({ "count" => "3" })
    response = Unisender::ContactCountResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([3], %i[count].map { |key| record.public_send(key) })
    assert_equal([3], %i[count].map { |key| response.public_send(key) })
  end

  def test_total_contacts_readers
    record = Unisender::TotalContacts.new({ "total" => 3 })
    response = Unisender::TotalContactsResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([3], %i[total].map { |key| record.public_send(key) })
    assert_equal([3], %i[total].map { |key| response.public_send(key) })
  end

  def test_message_version_readers
    record = Unisender::MessageVersion.new({ "message_id" => 1, "actual_version_id" => 2 })
    response = Unisender::MessageVersionResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1, 2], %i[message_id actual_version_id].map { |key| record.public_send(key) })
    assert_equal([1, 2], %i[message_id actual_version_id].map { |key| response.public_send(key) })
  end

  def test_web_version_readers
    record = Unisender::WebVersion.new({ "letter_id" => 1, "web_letter_link" => "https://example.test" })
    response = Unisender::WebVersionResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1, "https://example.test"], %i[letter_id web_letter_link].map { |key| record.public_send(key) })
    assert_equal([1, "https://example.test"], %i[letter_id web_letter_link].map { |key| response.public_send(key) })
  end

  def test_task_result_readers
    record = Unisender::TaskResult.new({ "task_uuid" => "task", "status" => "completed",
                                         "file_to_download" => "https://example.test" })
    response = Unisender::TaskResultResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal(["task", "completed", "https://example.test"], %i[task_uuid status file_to_download].map do |key|
      record.public_send(key)
    end)
    assert_equal(["task", "completed", "https://example.test"], %i[task_uuid status file_to_download].map do |key|
      response.public_send(key)
    end)
  end

  def test_nested_copies_are_mutable_and_do_not_change_the_record
    record = Unisender::Record.new({ "a" => [{ "b" => "original" }] })
    copy = record.to_h
    copy["a"][0]["b"].replace("changed")

    assert_equal "original", record.dig("a", 0, "b")
    assert_equal "#<Unisender::Record>", record.inspect
    refute_equal 1, record
  end

  def test_field_errors_hide_values
    [
      [Unisender::IdentifierRecord, { "id" => nil }],
      [Unisender::List, { "id" => 1, "title" => 12 }],
      [Unisender::List, { "id" => 1 }],
      [Unisender::ContactCount, { "count" => "secret" }]
    ].each do |model, data|
      error = assert_raises(Unisender::InvalidResponseError) { model.new(data) }

      refute_includes error.message, "secret"
    end
  end
end
