# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class DxInputsTest < Minitest::Test
  def test_subscription_accepts_email_and_named_modes
    client, transport = client_for({ "person_id" => 1 })
    client.subscribe(email: "a@b.test", list_ids: [1], double_optin: :already_confirmed, overwrite: :update)
    body = URI.decode_www_form(transport.requests.first[:body]).to_h

    assert_equal ["a@b.test", "3", "2"], body.values_at("fields[email]", "double_optin", "overwrite")
  end

  def test_import_accepts_records_and_aligns_columns
    client, transport = client_for({ "invalid" => 0 })
    client.import_contacts(records: [{ email: "a@b.test", Name: "One" }, { Name: "Two", email: "b@b.test" }])
    body = URI.decode_www_form(transport.requests.first[:body]).to_h

    assert_equal ["email", "Name", "b@b.test", "Two"],
                 body.values_at("field_names[0]", "field_names[1]", "data[1][0]", "data[1][1]")
  end

  def test_time_filters_use_the_operation_format
    client, transport = client_for([])
    time = Time.new(2026, 1, 2, 3, 4, 5, "+03:00")
    client.get_messages(date_from: time, date_to: time)

    assert_equal "2026-01-02 00:04", URI.decode_www_form(transport.requests.first[:body]).to_h["date_from"]
  end

  def test_invalid_record_reports_the_path_without_values
    client, transport = client_for({})
    error = assert_raises(Unisender::ValidationError) do
      client.import_contacts(records: [{ email: "a@b.test" }, { Name: "private-name" }])
    end

    assert_equal "records[1]", error.field
    assert_empty transport.requests
  end

  private

  def client_for(result)
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => result }))
    [Unisender::Client.new(api_key: "test-key", transport:), transport]
  end
end
