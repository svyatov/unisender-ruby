# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class OutcomeReportsTest < Minitest::Test
  def test_import_report_exposes_partial_failure
    result = { "total" => 2, "invalid" => 1, "log" => [{ "index" => "1", "code" => "e_email_invalid" }] }
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => result }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    report = client.import_contacts(field_names: ["email"], data: [["a@b.test"], ["invalid"]])

    assert_predicate report, :partial?
    assert_equal [1], report.failures.map(&:index)
    assert_raises(Unisender::PartialFailure) { report.raise_for_partial_failure! }
  end

  def test_batch_report_uses_global_failure_indices
    transport = ScriptedTransport.new(
      ScriptedTransport.reply({ "result" => { "total" => 1, "invalid" => 0 } }),
      ScriptedTransport.reply({ "result" => { "total" => 1, "invalid" => 1, "log" => [{ "index" => 0 }] } })
    )
    client = Unisender::Client.new(api_key: "test-key", transport:)
    error = assert_raises(Unisender::BatchError) do
      client.import_contacts_in_batches(field_names: ["email"], data: [["a@b.test"], ["bad"]], batch_size: 1)
    end

    assert_equal [1], error.report.failures.map(&:index)
    assert_equal 1, error.report.completed_batches
  end
end
