# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class OperationsTest < Minitest::Test
  cases = JSON.parse(File.read(File.join(__dir__, "fixtures/operations.json")))
  cases.each do |example|
    define_method("test_#{example.fetch('name')}_matches_documented_contract") do
      response, request = invoke_example(example, "args")

      assert_equal example.fetch("result"), response.data.fetch("result"), example.fetch("url")
      assert_equal "/en/api/#{example.fetch('wire')}", request.fetch(:uri).path
      assert_body(example.fetch("expected"), request)
    end

    define_method("test_#{example.fetch('name')}_accepts_all_documented_options") do
      _response, request = invoke_example(example, "options")

      assert_body(example.fetch("options_expected"), request)
    end

    define_method("test_#{example.fetch('name')}_propagates_api_errors") do
      failure = { "error" => "Rejected", "code" => "invalid_arg" }

      error = assert_raises(Unisender::APIError) { invoke_example(example, "args", failure) }

      assert_equal example.fetch("wire"), error.operation
    end
  end

  private

  def invoke_example(example, key, data = { "result" => example.fetch("result") })
    transport = ScriptedTransport.new(ScriptedTransport.reply(data))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    response = client.public_send(example.fetch("name"), **example.fetch(key).transform_keys(&:to_sym))
    [response, transport.requests.fetch(0)]
  end

  def assert_body(expected, request)
    expected = expected.merge("api_key" => "test-key", "format" => "json")

    assert_equal expected, URI.decode_www_form(request.fetch(:body)).to_h
  end
end
