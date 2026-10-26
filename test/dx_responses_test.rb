# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class DxResponsesTest < Minitest::Test
  def test_lists_are_typed_enumerable_responses
    response = client([{ "id" => 42, "title" => "News", "extra" => { "enabled" => true } }]).get_lists

    assert_equal [[42], "News", 200], [response.map(&:id), response.first.title, response.http_status]
    assert response.first.dig("extra", "enabled")
    assert_instance_of Unisender::List, response.result.first
  end

  def test_collection_lookup_and_enumerator
    response = client([{ "id" => 42, "title" => "News" }]).get_lists

    assert_equal [42, 42, 1, false], [response[0].id, response.fetch(0).id, response.size, response.empty?]
    assert_instance_of Enumerator, response.each
    assert_empty client([]).get_lists
  end

  def test_record_access_and_raw_data_remain_distinct
    response = client({ "count" => "500" }).get_contact_count(list_id: 1, params: { type: "address" })

    assert_equal [500, 500, "500"], [response.count, response.fetch("count"), response.data["result"]["count"]]
    copy = response.result.to_h
    copy["count"] = 0

    assert_equal 500, response.count
  end

  def test_boolean_predicate_preserves_false
    refute client(false).contact_in_lists?(email: "a@b.test", list_ids: [1], condition: :all)
  end

  def test_message_read_is_singular
    response = client([{ "id" => 1, "subject" => "News" }]).get_message(id: 1)

    assert_equal ["News", Unisender::Message], [response.subject, response.result.class]
    assert_raises(Unisender::NotFoundError) { client([]).get_message(id: 1) }
    assert_raises(Unisender::InvalidResponseError) { client([{ "id" => 1 }, { "id" => 2 }]).get_message(id: 1) }
  end

  def test_result_status_does_not_hide_http_metadata
    response = client({ "status" => "completed" }).get_campaign_status(campaign_id: 1)

    assert_equal "completed", response.status
    assert_equal 200, response.http_status
  end

  def test_invalid_membership_condition_is_local
    assert_raises(ArgumentError) do
      client(false).contact_in_lists?(email: "a@b.test", list_ids: [1], condition: :wrong)
    end
  end

  def test_record_lookup_methods
    response = client({ "id" => 1, "extra" => { "value" => 1 } }).create_list(title: "News")

    assert_equal [1, 1, 1], [response["id"], response.dig("extra", "value"), response.fetch("id")]
    assert_equal response.result, Unisender::IdentifierRecord.new(response.data.fetch("result"))
  end

  def test_invalid_table_shapes
    [{}, { "fields" => ["x"], "data" => [[]] }, { "fields" => [1], "data" => [[1]] }].each do |data|
      assert_raises(Unisender::InvalidResponseError) { client(data).get_visited_links(campaign_id: 1) }
    end
  end

  def test_pagination_and_task_shapes
    assert_raises(Unisender::InvalidResponseError) { client({ "id" => 1 }).each_page(:get_templates).first }
    assert_raises(Unisender::InvalidResponseError) { client([]).wait_for_task(task_uuid: "task") }
  end

  private

  def client(result)
    Unisender::Client.new(api_key: "test-key",
                          transport: ScriptedTransport.new(ScriptedTransport.reply({ "result" => result })))
  end
end
