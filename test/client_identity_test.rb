# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class ClientIdentityTest < Minitest::Test
  def test_both_protocols_send_library_and_ruby_versions
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [] })
    transport.enqueue(data: { "success" => true })
    client = Unisender::Client.new(api_key: "private-key", transport:)
    client.get_lists
    client.track_events(events: [{ name: "sale", email: "private@example.test" }])
    expected = "unisender-ruby/#{Unisender::VERSION} Ruby/#{RUBY_VERSION}"

    assert_equal([expected, expected], transport.requests.map { |request| request.headers["User-Agent"] })
  end
end
