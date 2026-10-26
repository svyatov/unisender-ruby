# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class ImportCellsTest < Minitest::Test
  def test_structured_cells_become_documented_scalars
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "invalid" => 0 } })
    client = Unisender::Client.new(api_key: "test", transport:)
    client.import_contacts(records: [{ email: "a@example.test", tags: %w[one two], email_list_ids: [1, 2],
                                       email_subscribe_times: [Time.utc(2026, 1, 1), "2026-01-02"] }])

    assert_equal ["one,two", "1,2", "2026-01-01 00:00:00,2026-01-02"],
                 transport.requests.first.form.values_at("data[0][1]", "data[0][2]", "data[0][3]")
  end

  def test_scalar_time_and_plain_strings_are_preserved
    rows = Unisender::RecordRows.new([{ email: "a", phone_subscribe_times: Time.utc(2026, 1, 1), tags: "one,two" }])

    assert_equal [["a", "2026-01-01 00:00:00", "one,two"]], rows.to_a
  end

  def test_invalid_structured_values_report_the_row
    identity = { email: "a" }
    [{ extra: [] }, { extra: {} }, { extra: Time.utc(2026) }, { tags: [true] },
     { tags: ["one,two"] }, { email_subscribe_times: [1] },
     { email_list_ids: [1], email_subscribe_times: %w[a b] }].each do |fields|
      error = assert_raises(Unisender::ValidationError) { Unisender::RecordRows.new([identity.merge(fields)]) }

      assert_match(/\Arecords\[0\]\.[a-z_]+\z/, error.field)
      assert_equal [:invalid_cell, 0], [error.code, error.index]
    end
  end
end
