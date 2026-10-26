# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class PayloadJSONTest < Minitest::Test
  def test_record_json_contains_fields_instead_of_an_object_description
    record = Unisender::Record.new({ "name" => "News", "extra" => [{ "enabled" => true }] })

    assert_equal({ "name" => "News", "extra" => [{ "enabled" => true }] }, JSON.parse(JSON.generate(record)))
  end

  def test_response_json_omits_transport_metadata
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [
                                                            { "id" => 1, "title" => "News" }
                                                          ], "warnings" => ["notice"] })
    response = Unisender::Client.new(api_key: "test", transport:).get_lists

    assert_equal [{ "id" => 1, "title" => "News" }], JSON.parse(response.to_json)
    copy = response.as_json
    copy.first["title"].replace("Changed")

    assert_equal "News", response.first.title
    assert_equal ["notice"], response.warnings
  end

  def test_raw_response_json_copies_nested_hashes
    response = Unisender::Response.new(data: { "result" => { "extra" => [1, nil] } }, status: 200, headers: {})

    assert_equal({ "extra" => [1, nil] }, response.as_json)
    assert_equal response.result, JSON.parse(JSON.generate(response))
  end
end
