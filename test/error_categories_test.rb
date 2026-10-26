# frozen_string_literal: true

require "test_helper"

class ErrorCategoriesTest < Minitest::Test
  API_CASES = {
    "invalid_api_key" => :authentication, "access_denied" => :authorization,
    "invalid_arg" => :invalid_argument, "not_enough_money" => :payment,
    "retry_later" => :transient, "api_call_limit_exceeded_for_api_key" => :rate_limit,
    "api_call_limit_exceeded_for_ip" => :rate_limit, "private-code" => :unknown
  }.freeze

  API_CASES.each do |code, category|
    define_method("test_api_category_#{code}") do
      response = Unisender::Response.new(data: { "code" => code }, status: 200, headers: { "x-request-id" => "r1" })
      error = Unisender::APIError.new(response).with_operation("getLists")

      assert_equal category, error.category
      assert_equal "r1", error.request_id
      refute_empty error.recovery_hint
    end
  end

  def test_http_categories_and_retry_safety
    { 401 => :authentication, 403 => :authorization, 429 => :rate_limit, 503 => :service_unavailable,
      400 => :http }.each do |status, category|
      response = Unisender::Response.new(data: {}, status:, headers: {})
      error = Unisender::HTTPError.new(response).with_operation("sendEmail")

      assert_equal category, error.category
      refute_predicate error, :safe_to_retry?
    end
  end

  def test_transport_categories_and_operation_safety
    timeout = Unisender::TimeoutError.new("Timeout").with_operation("getLists")
    transport = Unisender::TransportError.new("Transport", retryable: false)

    assert_equal %i[timeout transport invalid_response unknown],
                 [timeout.category, transport.category, Unisender::InvalidResponseError.new.category,
                  Unisender::Error.new.category]
    assert_predicate timeout, :safe_to_retry?
    refute_predicate transport, :safe_to_retry?
  end

  def test_unknown_errors_are_not_transient
    error = Unisender::Error.new

    refute_predicate error, :transient?
    assert_nil error.request_id
  end
end
