# frozen_string_literal: true

# No credentials or network access required.
require "unisender"

# Records requests and returns one deterministic response without a socket.
class FakeTransport
  attr_reader :requests

  def initialize
    @requests = []
  end

  def post(uri, headers:, body:)
    @requests << { uri:, headers:, body: }
    Unisender::HTTPResponse.new(
      status: 200, headers: { "x-request-id" => "offline-example" },
      body: '{"result":[{"id":42,"title":"Product news"}]}'
    )
  end
end

transport = FakeTransport.new
client = Unisender::Client.new(api_key: "test-key", transport:)
client.get_lists.result.each { |list| puts list.fetch("title") }
puts "Requests: #{transport.requests.size}"
