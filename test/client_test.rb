# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class ClientTest < Minitest::Test
  def test_posts_credentials_in_body_and_returns_result_with_warnings
    reply = { "result" => [{ "id" => 42 }], "warnings" => [{ "warning" => "example" }] }
    transport = ScriptedTransport.new(ScriptedTransport.reply(reply, headers: { "x-request-id" => "r1" }))
    response = Unisender::Client.new(api_key: "test-key", transport:).request("getLists")

    assert_equal [reply, 200, "r1"], [response.data, response.status, response.headers.fetch("x-request-id")]
    assert_get_lists_request(transport.requests.first)
  end

  def assert_get_lists_request(request)
    assert_equal "https://api.unisender.com/en/api/getLists", request[:uri].to_s
    assert_equal({ "api_key" => "test-key", "format" => "json" }, URI.decode_www_form(request[:body]).to_h)
  end
end

class RequestValidationTest < Minitest::Test
  def setup
    @transport = ScriptedTransport.new
    @client = Unisender::Client.new(api_key: "key", transport: @transport)
  end

  def test_rejects_invalid_credentials_and_language
    [nil, "", " \n", "key\r\nheader"].each do |key|
      assert_raises(ArgumentError) { Unisender::Client.new(api_key: key, transport: @transport) }
    end
    assert_raises(ArgumentError) { Unisender::Client.new(api_key: "key", language: :de, transport: @transport) }
  end

  def test_rejects_unsafe_method_paths
    ["../sendEmail", "getLists?x=1", "", "https://evil.example", "async/../sendEmail"].each do |method|
      assert_raises(ArgumentError) { @client.request(method) }
    end
    assert_empty @transport.requests
  end

  def test_rejects_invalid_parameters
    [{ api_key: "evil" }, { "format" => "html" }, { a: 1, "a" => 2 }, { field: Object.new },
     { "a[b]" => 1 }, { a: Float::INFINITY }, { text: "\xFF".b }, { a: { x: 1, "x" => 2 } },
     { text: "\xFF".dup.force_encoding(Encoding::UTF_8) }].each do |params|
      assert_raises(ArgumentError) { @client.request("getLists", params:) }
    end
    assert_empty @transport.requests
  end

  def test_rejects_cyclic_parameters
    recursive = []
    recursive << recursive

    assert_raises(ArgumentError) { @client.request("getLists", params: { a: recursive }) }
    assert_empty @transport.requests
  end
end
