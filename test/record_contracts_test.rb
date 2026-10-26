# frozen_string_literal: true

require "test_helper"

class RecordContractsTest < Minitest::Test
  def test_identifier_record_readers
    record = Unisender::IdentifierRecord.new({ "id" => 1 })
    response = Unisender::IdentifierRecordResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1], %i[id].map { |key| record.public_send(key) })
    assert_equal([1], %i[id].map { |key| response.public_send(key) })
  end

  def test_list_readers
    record = Unisender::List.new({ "id" => 1, "title" => "News" })
    response = Unisender::ListResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1, "News"], %i[id title].map { |key| record.public_send(key) })
    assert_equal([1, "News"], %i[id title].map { |key| response.public_send(key) })
  end

  def test_message_readers
    record = Unisender::Message.new({ "id" => 1, "subject" => "News", "body" => "<p>News</p>",
                                      "sender_name" => "Sender", "sender_email" => "sender@example.test" })
    response = Unisender::MessageResponse.new(data: {}, status: 200, headers: {}, result: record)
    expected = [1, "News", "<p>News</p>", "Sender", "sender@example.test"]
    fields = %i[id subject body sender_name sender_email]

    assert_equal(expected, fields.map { |key| record.public_send(key) })
    assert_equal(expected, fields.map { |key| response.public_send(key) })
  end

  def test_campaign_readers
    record = Unisender::Campaign.new({ "id" => 1, "status" => "completed", "subject" => "News" })
    response = Unisender::CampaignResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1, "completed", "News"], %i[id status subject].map { |key| record.public_send(key) })
    assert_equal([1, "completed", "News"], %i[id status subject].map { |key| response.public_send(key) })
  end

  def test_template_readers
    record = Unisender::Template.new({ "id" => 1, "title" => "News", "subject" => "News", "body" => "text" })
    response = Unisender::TemplateResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1, "News", "News", "text"], %i[id title subject body].map { |key| record.public_send(key) })
    assert_equal([1, "News", "News", "text"], %i[id title subject body].map { |key| response.public_send(key) })
  end

  def test_field_readers
    record = Unisender::Field.new({ "id" => 1, "name" => "Name", "type" => "string" })
    response = Unisender::FieldResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1, "Name", "string"], %i[id name type].map { |key| record.public_send(key) })
    assert_equal([1, "Name", "string"], %i[id name type].map { |key| response.public_send(key) })
  end

  def test_tag_readers
    record = Unisender::Tag.new({ "id" => 1, "name" => "News" })
    response = Unisender::TagResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1, "News"], %i[id name].map { |key| record.public_send(key) })
    assert_equal([1, "News"], %i[id name].map { |key| response.public_send(key) })
  end

  def test_note_readers
    record = Unisender::Note.new({ "id" => 1, "content" => "Note" })
    response = Unisender::NoteResponse.new(data: {}, status: 200, headers: {}, result: record)

    assert_equal([1, "Note"], %i[id content].map { |key| record.public_send(key) })
    assert_equal([1, "Note"], %i[id content].map { |key| response.public_send(key) })
  end
end
