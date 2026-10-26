# frozen_string_literal: true

require "test_helper"

class ReportBoundariesTest < Minitest::Test
  def test_import_reports_distinguish_rejected_and_unknown_counts
    rejected = Unisender::ImportResult.new({ "invalid" => 2, "total" => 2 })
    unknown = Unisender::ImportResult.new({ "invalid" => 1 })

    assert_equal [false, false, false], [rejected.complete?, rejected.partial?, rejected.uncertain?]
    assert_equal [false, false, true], [unknown.complete?, unknown.partial?, unknown.uncertain?]
  end

  def test_import_warnings_are_not_failures
    result = Unisender::ImportResult.new({ "invalid" => 0, "log" => [{ "code" => "w_common_overlimit" }] })

    assert_empty result.failures
    assert_predicate result, :complete?
  end

  def test_send_reports_cover_legacy_success_and_partial_acceptance
    legacy = Unisender::SendResult.new({ "email_id" => 1 })
    mixed = Unisender::SendResult.new({ "recipients" => [
                                        { "id" => "ok", "index" => 0, "email" => "a@b.test" },
                                        { "index" => 1,
                                          "errors" => [{ "code" => "invalid_email", "message" => "Invalid" }] }
                                      ] })

    assert_equal [true, false, false], [legacy.complete?, legacy.partial?, legacy.uncertain?]
    assert_equal [false, true, false], [mixed.complete?, mixed.partial?, mixed.uncertain?]
    assert_equal([[1, "invalid_email", "Invalid"]], mixed.failures.map { |f| [f.index, f.code, f.message] })
  end

  def test_send_reports_do_not_claim_unknown_acceptance
    [[], [{}]].each do |recipients|
      result = Unisender::SendResult.new({ "recipients" => recipients })

      assert_equal [false, false, true], [result.complete?, result.partial?, result.uncertain?]
    end
  end

  def test_invalid_diagnostics_are_rejected
    ["bad", ["bad"]].each do |errors|
      assert_raises(Unisender::InvalidResponseError) { Unisender::ImportResult.new({ "invalid" => 1, "log" => errors }) }
    end
  end

  def test_batch_totals_only_use_known_import_results
    response = Unisender::ImportResponse.new(data: {}, status: 200, headers: {},
                                             result: Unisender::ImportResult.new({ "invalid" => 0, "total" => 2 }))
    report = Unisender::BatchReport.new([response])

    assert_equal [2, 0, false, false, []],
                 [report.total, report.invalid, report.partial?, report.uncertain?, report.failures]
    assert_same response, response.raise_for_partial_failure!
  end

  def test_network_failure_keeps_counts_unknown
    report = Unisender::BatchReport.new([], error: Unisender::TimeoutError.new("Timeout"), failed_range: 0...1)

    assert_equal [nil, nil, false, true], [report.total, report.invalid, report.partial?, report.uncertain?]
  end

  def test_event_error_preserves_uncertain_acceptance
    response = Unisender::Response.new(data: {}, status: 400, headers: {})
    error = Unisender::EventError.new(response)
    report = Unisender::BatchReport.new([], error:, failed_range: 0...1)

    assert_equal [false, false, true, []],
                 [error.report.complete?, error.report.partial?, error.report.uncertain?, error.report.failures]
    assert_predicate report, :uncertain?
  end

  def test_failure_without_an_index_is_not_assigned_one
    failure = Unisender::Failure.new({ "message" => "Unknown row" })

    assert_same failure, failure.with_offset(10)
    assert_nil failure.index
  end
end
