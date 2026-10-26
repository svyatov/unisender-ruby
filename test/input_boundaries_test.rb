# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class InputBoundariesTest < Minitest::Test
  def setup
    replies = Array.new(10) { ScriptedTransport.reply({ "result" => { "invalid" => 0, "person_id" => 1 } }) }
    @transport = ScriptedTransport.new(*replies)
    @client = Unisender::Client.new(api_key: "test-key", transport: @transport)
  end

  def test_streaming_records_keep_one_schema
    records = [{ email: "a@b.test", Name: "One" }, { Name: "Two", email: "b@b.test" }].each
    report = @client.import_contacts_in_batches(records:, batch_size: 1)

    assert_equal 2, report.completed_batches
    assert_equal 2, @transport.requests.size
  end

  def test_conflicting_import_forms_fail_before_transport
    assert_raises(Unisender::ValidationError) do
      @client.import_contacts(records: [], field_names: ["email"], data: [])
    end
    assert_raises(Unisender::ValidationError) do
      @client.import_contacts_in_batches(records: [], field_names: ["email"], data: [])
    end
    assert_raises(Unisender::ValidationError) { @client.each_import_batch }
  end

  def test_invalid_record_columns_have_safe_diagnostics
    [[1], [{ email: "a", "email" => "b" }], [{ email: "a" }, { email: "b", Name: "extra" }]].each do |records|
      error = assert_raises(Unisender::ValidationError) { @client.import_contacts(records:) }

      assert_match(/records\[/, error.field)
    end
    assert_empty @transport.requests
  end

  def test_invalid_subscription_modes_are_local
    [:unknown, 2, "3"].each do |mode|
      assert_raises(Unisender::ValidationError) do
        @client.subscribe(email: "a@b.test", list_ids: [1], double_optin: mode)
      end
    end
    assert_empty @transport.requests
  end

  def test_subscription_rejects_conflicting_and_missing_email
    [
      { email: "a", fields: { email: "b" } },
      { fields: { email: "a", "email" => "b" } },
      { fields: { Name: "name" } },
      { email: "" }
    ].each do |args|
      assert_raises(Unisender::ValidationError) { @client.subscribe(list_ids: [1], **args) }
    end
    assert_empty @transport.requests
  end

  def test_same_email_does_not_conflict
    @client.subscribe(email: "a@b.test", fields: { email: "a@b.test" }, list_ids: [1])

    assert_equal 1, @transport.requests.size
  end
end
