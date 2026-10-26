# frozen_string_literal: true

require "test_helper"

class RecoveryCategoriesTest < Minitest::Test
  def test_local_error_categories_are_actionable
    errors = [Unisender::NotFoundError.new, Unisender::ClientClosedError.new,
              Unisender::PaginationError.new(operation: "get_templates", next_offset: 10, completed_pages: 1)]

    assert_equal %i[not_found client_closed pagination_limit], errors.map(&:category)
  end

  def test_wrappers_preserve_underlying_category_and_request_id
    response = Unisender::Response.new(data: {}, status: 503, headers: { "x-request-id" => "example-id" })
    underlying = Unisender::HTTPError.new(response)
    batch = Unisender::BatchError.new(completed_responses: [], failed_range: 0...1, error: underlying)
    campaign = Unisender::CampaignWorkflowError.new(response, underlying)

    assert_equal %i[service_unavailable service_unavailable], [batch.category, campaign.category]
    assert_equal %w[example-id example-id], [batch.request_id, campaign.request_id]
  end

  def test_task_and_partial_categories
    response = Unisender::Response.new(data: {}, status: 200, headers: {})
    errors = [Unisender::TaskError.new(response), Unisender::TaskFailedError.new(response),
              Unisender::UnknownTaskStateError.new(response), Unisender::PartialFailure.new(response),
              Unisender::DownloadError.new(reason: :too_large)]

    assert_equal %i[task_state task_failed unknown_task_state partial_failure download], errors.map(&:category)
  end

  def test_wrapped_validation_and_application_errors
    [Unisender::ValidationError.new(field: "data", code: :invalid_rows), RuntimeError.new("private")].each do |error|
      wrappers = [Unisender::BatchError.new(completed_responses: [], failed_range: 0...0, error:),
                  Unisender::CampaignWorkflowError.new(nil, error)]
      expected = error.is_a?(Unisender::ValidationError) ? :invalid_argument : :unexpected

      assert_equal [expected, expected], wrappers.map(&:category)
      assert_equal [nil, nil], wrappers.map(&:request_id)
    end
  end
end
