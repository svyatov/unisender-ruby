# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class ErrorDiagnosticsTest < Minitest::Test
  def test_api_failure_identifies_the_operation_and_documented_code
    error = failure({ "error" => "private contact", "code" => "invalid_arg" })

    assert_equal "getLists", error.operation
    assert_equal "UniSender getLists failed: invalid_arg", error.message
    refute_includes error.message, "private contact"
  end

  def test_http_failure_identifies_the_operation_and_status
    error = failure({}, status: 503)

    assert_equal "UniSender getLists failed: HTTP 503", error.message
  end

  def test_unknown_error_codes_and_methods_are_not_copied_into_messages
    error = failure({ "error" => "private contact", "code" => "privatecontact" }, method: "privatekey")

    assert_equal "UniSender request failed: API error", error.message
    assert_nil error.operation
    refute_match(/privatecontact|privatekey/, error.full_message)
  end

  def test_transport_failures_identify_the_operation_without_exposing_the_request
    transport = ScriptedTransport.new(Unisender::TimeoutError.new("UniSender request timed out"))
    client = Unisender::Client.new(api_key: "private-key", transport:)
    error = assert_raises(Unisender::TimeoutError) { client.get_lists }

    assert_equal ["getLists", true], [error.operation, error.message.include?("getLists")]
    refute_includes error.message, "private-key"
  end

  def test_event_failure_identifies_the_operation_and_preserves_partial_acceptance
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "code" => "invalid_params" }, status: 400))
    client = Unisender::Client.new(api_key: "private-key", transport:)
    error = assert_raises(Unisender::EventError) do
      client.track_events(events: [{ name: "purchase", email: "person@example.com" }])
    end

    assert_equal ["track_events", "UniSender track_events failed: HTTP 400", true],
                 [error.operation, error.message, error.possibly_partially_accepted?]
  end

  private

  def failure(data, status: 200, method: "getLists")
    transport = ScriptedTransport.new(ScriptedTransport.reply(data, status:))
    client = Unisender::Client.new(api_key: "private-key", transport:)
    assert_raises(Unisender::Error) { client.request(method) }
  end
end
