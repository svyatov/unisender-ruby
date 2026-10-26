# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class StructuredDiagnosticsTest < Minitest::Test
  def test_invalid_input_has_safe_path_and_types
    client = Unisender::Client.new(api_key: "private-key")
    error = assert_raises(Unisender::ValidationError) { client.create_list(title: false) }

    assert_equal %w[title Boolean createList], [error.path, error.actual_type, error.operation]
    assert_includes error.documentation_url, "/createlist/"
  end

  def test_result_error_preserves_request_context
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [{ "id" => [] }] },
                                                          headers: { "x-request-id" => "request-1" })
    error = assert_raises(Unisender::InvalidResponseError) do
      Unisender::Client.new(api_key: "test", transport:).get_lists
    end

    assert_equal ["result[0].id", "String or Integer", "Array", 200, "request-1"],
                 [error.path, error.expected_type, error.actual_type, error.http_status, error.request_id]
    assert_predicate error.diagnostics, :frozen?
  end

  def test_paths_redact_dynamic_names
    error = Unisender::ValidationError.new(field: "fields[private@example.test]", code: :invalid_type)

    assert_equal "fields[*]", error.path
    assert_equal "records[2].*", Unisender::Diagnostics.input_path("records[2].private_name")
    assert_equal "parameters", Unisender::Diagnostics.input_path("private-name")
  end

  def test_wrappers_preserve_known_progress_and_underlying_diagnostics
    response = Unisender::Response.new(data: { "code" => "invalid_arg", "error" => "private-value" },
                                       status: 200, headers: { "x-request-id" => "request-1" })
    underlying = Unisender::APIError.new(response).with_operation("importContacts")
    error = Unisender::BatchError.new(completed_responses: [], failed_range: 3...4, error: underlying)

    assert_equal ["invalid_arg", "importContacts", 3, 4],
                 error.diagnostics.values_at(:code, :operation, :failed_from, :failed_to)
    refute_includes error.diagnostics.inspect, "private-value"
  end

  def test_arbitrary_errors_and_unknown_codes_stay_private
    response = Unisender::Response.new(data: { "code" => "private-code" }, status: 400, headers: {})
    error = Unisender::APIError.new(response)
    wrapper = Unisender::BatchError.new(completed_responses: [], failed_range: 0...1,
                                        error: RuntimeError.new("private-value"))

    refute error.diagnostics.key?(:code)
    refute_includes wrapper.diagnostics.inspect, "private-value"
    assert_equal({ category: "unknown" }, Unisender::Error.new.diagnostics)
  end

  def test_type_names_do_not_use_custom_class_names
    values = ["a", 1, 1.0, :a, [], {}, nil, true, false, Object.new]

    assert_equal(%w[String Integer Float Symbol Array Hash NilClass Boolean Boolean Object],
                 values.map { |value| Unisender::Diagnostics.type_name(value) })
  end

  def test_validation_diagnostics_include_documentation_and_types
    error = Unisender::ValidationError.new(field: "data[2][0]", code: :invalid_type,
                                           expected_type: "String", actual_type: "Array")
    error.with_operation("importContacts")

    assert_equal "String", error.diagnostics[:expected_type]
    assert_equal "Array", error.diagnostics[:actual_type]
    assert_equal "data[2][0]", error.diagnostics[:path]
  end

  def test_documentation_links_and_invalid_key_encoding
    assert_includes Unisender::Error.new.with_operation("getLists").documentation_url, "/getlists/"
    client = Unisender::Client.new(api_key: "test")
    assert_raises(Unisender::ValidationError) { client.request("getLists", params: { "\xFF".b => 1 }) }
  end

  def test_nested_record_errors_keep_the_parent_path
    transport = Unisender::Testing::Transport.new.enqueue(data: {
                                                            "result" => { "email" => { "email" => "a@example.test",
                                                                                       "rating" => "private-value" } }
                                                          })
    error = assert_raises(Unisender::InvalidResponseError) do
      Unisender::Client.new(api_key: "test", transport:).get_contact(email: "a@example.test")
    end

    assert_equal "result.email.rating", error.path
    refute_includes error.diagnostics.inspect, "private-value"
  end
end
