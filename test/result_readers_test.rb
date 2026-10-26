# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class ResultReadersTest < Minitest::Test
  def test_update_field_exposes_optional_identifier
    transport = Unisender::Testing::Transport.new.enqueue(data: { "id" => 12 })
    response = Unisender::Client.new(api_key: "test", transport:).update_field(id: 12, name: "City")

    assert_equal 12, response.id
  end

  def test_note_metadata_is_readable
    note = Unisender::Note.new({ "id" => 1, "content" => "Note", "user_id" => 2, "subscriber_id" => 3,
                                 "origin" => "api", "is_pinned" => false, "created_at" => "2026-01-01" })

    assert_equal [2, 3, "api", false], [note.user_id, note.subscriber_id, note.origin, note.is_pinned]
    assert_equal ["2026-01-01", nil, nil], [note.created_at, note.updated_at, note.pinned_at]
  end

  def test_response_forwards_note_metadata
    note = Unisender::Note.new({ "id" => 1, "content" => "Note", "is_pinned" => true })
    response = Unisender::NoteResponse.new(data: {}, status: 200, headers: {}, result: note)

    assert_equal [nil, nil, nil, true, nil, nil, nil],
                 [response.user_id, response.subscriber_id, response.origin, response.is_pinned,
                  response.created_at, response.updated_at, response.pinned_at]
    assert_raises(Unisender::InvalidResponseError) { Unisender::Note.new({ "id" => 1, "content" => "N", "is_pinned" => 1 }) }
  end

  def test_legacy_id_and_service_notice
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] })
    transport.enqueue(data: { "message" => "Sent" })
    client = Unisender::Client.new(api_key: "test", transport:)

    assert_nil client.update_field(id: 1, name: "City").id
    assert_equal "Sent", client.send_test_email(email: "a@example.test", id: 1).message
  end

  def test_campaign_count_is_optional_and_normalized
    result = Unisender::CampaignCreated.new({ "campaign_id" => 1, "status" => "scheduled", "count" => "2" })
    response = Unisender::CampaignCreatedResponse.new(data: {}, status: 200, headers: {}, result:)

    assert_equal 2, response.count
  end
end
