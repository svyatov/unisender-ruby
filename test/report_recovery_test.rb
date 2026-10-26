# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class ReportRecoveryTest < Minitest::Test
  def test_direct_import_accessors_and_unknown_totals
    response = import_response({ "invalid" => 0 })
    batch = Unisender::BatchReport.new([response])

    assert_equal [nil, 0, false], [response.total, response.invalid, response.uncertain?]
    assert_nil batch.total
  end

  def test_partial_first_batch_preserves_failures_and_totals
    response = import_response({ "invalid" => 1, "total" => 2, "log" => [{ "index" => 0 }] })
    error = Unisender::PartialFailure.new(response)
    report = Unisender::BatchReport.new([], error:, failed_range: 0...2)

    assert_equal [2, 1, true, false], [report.total, report.invalid, report.partial?, report.uncertain?]
    assert_equal [0], report.failures.map(&:index)
    assert_equal [0], Unisender::BatchReport.new([], error:).failures.map(&:index)
  end

  def test_missing_partial_response_shape_is_uncertain
    raw = Unisender::Response.new(data: {}, status: 200, headers: {})
    report = Unisender::BatchReport.new([], error: Unisender::PartialFailure.new(raw), failed_range: 0...1)

    assert_predicate report, :uncertain?
    assert_empty report.failures
  end

  def test_event_batches_have_no_invented_import_totals
    event = Unisender::EventResult.new({ "success" => true })
    response = Unisender::EventResponse.new(data: {}, status: 200, headers: {}, result: event)
    report = Unisender::BatchReport.new([response])

    assert_nil report.total
    assert_nil report.invalid
  end

  def test_authorization_rejection_is_known
    response = Unisender::Response.new(data: {}, status: 401, headers: {})

    refute_predicate Unisender::EventError.new(response).report, :uncertain?
  end

  def test_source_failure_does_not_replay_requests
    source = Enumerator.new { |_output| raise ArgumentError, "Source unavailable" }
    transport = ScriptedTransport.new
    client = Unisender::Client.new(api_key: "test-key", transport:)
    error = assert_raises(Unisender::BatchError) do
      client.import_contacts_in_batches(field_names: ["email"], data: source)
    end

    assert_equal 0...0, error.failed_range
    assert_empty transport.requests
  end

  def test_send_accessors_report_accepted_recipients
    result = Unisender::SendResult.new({ "recipients" => [{ "id" => "1", "index" => 0 }] })
    response = Unisender::SendResponse.new(data: {}, status: 200, headers: {}, result:)

    assert_equal [true, false, nil, ["1"]],
                 [response.complete?, response.partial?, response.email_id, response.recipients.map(&:id)]
    refute_predicate response, :uncertain?
  end

  private

  def import_response(data)
    Unisender::ImportResponse.new(data: {}, status: 200, headers: {}, result: Unisender::ImportResult.new(data))
  end
end
