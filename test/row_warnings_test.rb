# frozen_string_literal: true

require "test_helper"

class RowWarningsTest < Minitest::Test
  def test_accepted_imports_keep_typed_warnings
    result = Unisender::ImportResult.new({ "invalid" => 0, "total" => 2,
                                           "log" => [{ "index" => 1, "code" => "w_common_overlimit" }] })
    response = Unisender::ImportResponse.new(data: {}, status: 200, headers: {}, result:)

    assert_equal [true, []], [response.complete?, response.failures]
    assert_equal [1], response.row_warnings.map(&:index)
  end

  def test_batch_warning_indices_include_prior_input
    responses = [warning_response(2), warning_response(3)]

    assert_equal [0, 2], Unisender::BatchReport.new(responses).row_warnings.map(&:index)
  end

  def test_unknown_prior_counts_do_not_invent_indices
    report = Unisender::BatchReport.new([warning_response(nil), warning_response(2)])

    assert_equal [0, nil], report.row_warnings.map(&:index)
  end

  def test_failed_batch_warnings_use_the_known_failure_range
    response = warning_response(1)
    report = Unisender::BatchReport.new([], error: Unisender::PartialFailure.new(response), failed_range: 5...6)

    assert_equal [5], report.row_warnings.map(&:index)
    assert_empty Unisender::BatchReport.new([Unisender::Response.new(data: {}, status: 200, headers: {})]).row_warnings
  end

  def test_missing_failure_range_does_not_invent_an_index
    report = Unisender::BatchReport.new([], error: Unisender::PartialFailure.new(warning_response(1)))

    assert_equal [nil], report.row_warnings.map(&:index)
  end

  private

  def warning_response(total)
    result = Unisender::ImportResult.new({ "invalid" => 0, "total" => total,
                                           "log" => [{ "index" => 0, "code" => "w_notice" }] })
    Unisender::ImportResponse.new(data: {}, status: 200, headers: {}, result:)
  end
end
