# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class StructuredValidationTest < Minitest::Test
  def test_required_value_failure_has_field_and_operation
    client = Unisender::Client.new(api_key: "test")
    error = assert_raises(ArgumentError) { client.create_list(title: "") }

    assert_kind_of Unisender::ValidationError, error
    assert_equal ["title", :required, "createList"], [error.field, error.code, error.operation]
  end

  def test_validation_diagnostics_never_recommend_retry
    error = Unisender::ValidationError.new(field: "title", code: :required)

    assert_equal [:invalid_argument, false, false], [error.category, error.transient?, error.safe_to_retry?]
    assert_equal "Check the operation parameters.", error.recovery_hint
  end

  def test_event_validation_names_the_operation
    error = assert_raises(Unisender::ValidationError) do
      Unisender::Client.new(api_key: "test").track_events(events: [])
    end

    assert_equal %w[events track_events], [error.field, error.operation]
  end
end
