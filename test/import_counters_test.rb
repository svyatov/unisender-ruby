# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class ImportCountersTest < Minitest::Test
  def test_import_counters_are_typed_response_readers
    response = sample_import

    assert_equal [2, 3, 4, 5], [response.inserted, response.updated, response.deleted, response.new_emails]
    assert_equal "2", response.data.fetch("result").fetch("inserted")
  end

  def test_import_counters_are_typed_result_readers
    result = sample_import.result

    assert_equal [2, 3, 4, 5], [result.inserted, result.updated, result.deleted, result.new_emails]
  end

  def test_omitted_counters_remain_unknown
    response = import_result({ "invalid" => 0 })

    assert_equal [nil, nil, nil, nil], [response.inserted, response.updated, response.deleted, response.new_emails]
  end

  def test_present_malformed_counters_are_rejected_during_decode
    assert_raises(Unisender::InvalidResponseError) { import_result({ "invalid" => 0, "updated" => "bad" }) }
  end

  private

  def sample_import
    import_result({ "total" => 10, "invalid" => 0, "inserted" => "2", "updated" => 3,
                    "deleted" => 4, "new_emails" => 5 })
  end

  def import_result(result)
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => result })
    Unisender::Client.new(api_key: "test-key", transport:).import_contacts(records: [{ email: "a@b.test" }])
  end
end
