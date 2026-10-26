# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class EventsTest < Minitest::Test
  VALID = { name: "sale", email: "u@example.test" }.freeze
  EXPECTED = { "events" => [{ "name" => "purchase", "email" => "user@example.test",
                              "items" => [{ "count" => 2, "paid" => true, "tag" => nil }] }] }.freeze
  INVALID = [
    [], Array.new(26, VALID), [1], [{}], [VALID.merge(name: "x" * 41)], [VALID.merge(email: "Иван@example.test")],
    [VALID.merge(name: nil)], [VALID.merge(extra: Float::NAN)], [VALID.merge(extra: Object.new)],
    [VALID.merge("name" => "duplicate")], [VALID.merge(extra: "\xFF".b)],
    [VALID.merge((1..24).to_h { |i| ["field#{i}", i] })], [VALID.merge(extra: "x" * 133_121)]
  ].freeze

  def test_sends_json_and_bearer_authentication_to_the_event_endpoint
    event = { name: "purchase", email: "user@example.test", items: [{ count: 2, paid: true, tag: nil }] }
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "success" => true }))
    response = Unisender::Client.new(api_key: "test-key", transport:).track_events(events: [event])
    request = transport.requests.first

    assert_equal [{ "success" => true }, "https://event.unisender.com/v1/events/"],
                 [response.as_json, request[:uri].to_s]
    assert_equal({ "Content-Type" => "application/json", "Authorization" => "Bearer test-key",
                   "User-Agent" => Unisender::Client::USER_AGENT }, request[:headers])
    assert_equal EXPECTED, JSON.parse(request[:body])
  end

  def test_exposes_event_errors_without_replaying_a_partially_accepted_batch
    [400, 401, 500].each do |status|
      payload = { "code" => "invalid_params", "details" => { "invalidEvents" => [] } }
      transport = ScriptedTransport.new(ScriptedTransport.reply(payload, status:))
      client = Unisender::Client.new(api_key: "test-key", transport:)
      error = assert_raises(Unisender::EventError) { client.track_events(events: [VALID]) }

      assert_equal [status == 400, "invalid_params", payload["details"]],
                   [error.possibly_partially_accepted?, error.code, error.details]
      assert_equal 1, transport.requests.size
    end
  end

  def test_rejects_malformed_event_payloads_before_sending
    transport = ScriptedTransport.new
    client = Unisender::Client.new(api_key: "test-key", transport:)

    INVALID.each { |events| assert_raises(ArgumentError) { client.track_events(events:) } }

    assert_empty transport.requests
  end
end
