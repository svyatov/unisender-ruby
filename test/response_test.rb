# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class ResponseTest < Minitest::Test
  def test_http_failures_preserve_status_and_headers
    ["<html>Unavailable</html>", "[]", '{"result":[]}', '{"code":"denied","error":"sensitive"}'].each do |body|
      error = assert_raises(Unisender::HTTPError) { client(body, 503).request("getLists") }

      assert_equal [503, "2"], [error.response.status, error.response.headers["retry-after"]]
      refute_includes error.message, body
    end
  end

  def test_invalid_success_envelopes_do_not_expose_parser_details
    ["not json", "[]", "null", "42", "{}", '{"warnings":[]}'].each do |body|
      error = assert_raises(Unisender::InvalidResponseError) { client(body).request("getLists") }

      assert_nil error.cause
      refute_includes error.message, body
    end
  end

  def test_api_errors_preserve_details_and_discard_result
    body = '{"result":{"id":42},"error":"Bad contact person@example.test","code":"invalid_arg"}'
    error = assert_raises(Unisender::APIError) { client(body).request("getContact") }

    assert_equal ["invalid_arg", "Bad contact person@example.test", false],
                 [error.code, error.details, error.response.data.key?("result")]
    assert_nil error.cause
  end

  def test_inspection_and_exception_messages_are_safe
    error = assert_raises(Unisender::APIError) { client('{"error":"person@example.test"}').request("getContact") }

    refute_includes [error.message, error.inspect, error.response.inspect, client("{}").inspect].join,
                    "person@example.test"
    refute_includes client("{}").inspect, "test-key"
  end

  def test_response_data_and_nested_values_are_immutable
    response = client('{"result":{"email":"person@example.test","rows":[1,true,null,2.5]},"extra":"retained"}')
               .request("getContact")

    assert_equal [[], "retained", true], [response.warnings, response.data["extra"], response.frozen?]
    assert_raises(FrozenError) { response.result["email"].replace("changed") }
    assert_raises(FrozenError) { response.result["rows"] << "changed" }
  end

  def test_headers_are_immutable_and_hidden_in_inspection
    response = client('{"result":true}').request("getContact")

    assert_raises(FrozenError) { response.headers["new"] = "changed" }
    refute_includes response.inspect, "retry-after"
  end

  def test_transport_response_inspection_does_not_expose_payload_or_headers
    http = Unisender::HTTPResponse.new(status: 200, headers: { "set-cookie" => "session-secret" },
                                       body: '{"result":"person@example.test"}')

    refute_includes [http.inspect, http.to_s].join, "person@example.test"
    refute_includes [http.inspect, http.to_s].join, "session-secret"
  end

  private

  def client(body, status = 200)
    reply = Unisender::HTTPResponse.new(status:, headers: { "retry-after" => "2" }, body:)
    Unisender::Client.new(api_key: "test-key", transport: ScriptedTransport.new(reply))
  end
end
