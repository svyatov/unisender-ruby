# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class NestedFailureDiagnosticsTest < Minitest::Test
  def test_import_log_errors_include_the_container_and_position
    base = { "invalid" => 1 }
    [{ "log" => [{ "code" => 123 }] }, { "log" => false }, { "log" => [false] }].zip(
      ["result.log[0].code", "result.log", "result.log[0]"]
    ).each do |fields, path|
      transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => base.merge(fields) })
      error = assert_raises(Unisender::InvalidResponseError) do
        Unisender::Client.new(api_key: "test", transport:).import_contacts(records: [{ email: "a@example.test" }])
      end

      assert_equal path, error.path
    end
  end

  def test_recipient_errors_include_both_positions
    result = [{ "errors" => [{ "code" => 123 }] }]
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => result })
    error = assert_raises(Unisender::InvalidResponseError) do
      Unisender::Client.new(api_key: "test", transport:).send_email(
        email: "a@example.test", sender_email: "b@example.test", sender_name: "Shop",
        list_id: 1, subject: "Hi", body: "Hi"
      )
    end

    assert_equal "result.recipients[0].errors[0].code", error.path
  end
end
