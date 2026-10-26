# frozen_string_literal: true

require "test_helper"
require "unisender/webhooks"

class WebhooksTest < Minitest::Test
  def payload(key: "events", extra: "")
    <<~JSON.chomp
      {"unknown":"Привет \\"auth\\"", "events_by_user":[{"login":"test","#{key}":[
      {"event_name":"email_status","event_time":"2026-01-01 00:00:00","event_data":{"future":1}}]}],
      #{extra}"auth":"test-key"}
    JSON
  end

  def signed(body = payload)
    body.sub('"test-key"', %("#{Digest::MD5.hexdigest(body)}"))
  end

  def verify(body, **)
    Unisender::Webhooks.verify(body:, api_key: "test-key", **)
  end

  def test_preserves_original_bytes_unknown_fields_and_typed_events
    notification = verify(signed)

    assert_equal "test", notification.users.first.login
    assert_equal ["email_status", "2026-01-01 00:00:00", 1],
                 notification.events.map { |event|
                   [event.event_name, event.event_time, event.event_data["future"]]
                 }.first
    assert_includes notification["unknown"], "Привет"
  end

  def test_capital_events_and_gzip
    body = signed(payload(key: "Events"))
    compressed = StringIO.new
    Zlib::GzipWriter.wrap(compressed) { |gzip| gzip.write(body) }

    assert_equal 1, verify(compressed.string, content_encoding: "gzip").events.size
  end

  def test_authentication_is_sensitive_to_whitespace_and_key
    assert_raises(Unisender::WebhookError) { verify("#{signed} ") }
    assert_raises(Unisender::WebhookError) { Unisender::Webhooks.verify(body: signed, api_key: "wrong") }
    assert_raises(Unisender::WebhookError) { verify(payload) }
  end

  def test_duplicates_and_malformed_shapes
    bodies = ["[]", "{", "{}", signed(payload(extra: '"auth":"x",')),
              signed(payload(key: "other")), signed(payload(extra: '"events_by_user":[],'))]

    bodies.each { |body| assert_raises(Unisender::WebhookError) { verify(body) } }
  end

  def test_bounds_encodings_and_conflicting_keys
    assert_raises(Unisender::WebhookError) { verify(signed, max_bytes: 10) }
    assert_raises(Unisender::WebhookError) { verify(signed, max_decompressed_bytes: 10) }
    assert_raises(Unisender::WebhookError) { verify(signed, max_events: 0) }
  end

  def test_corrupt_and_unsupported_compression
    assert_raises(Unisender::WebhookError) { verify("bad", content_encoding: "gzip") }
    assert_raises(Unisender::WebhookError) { verify(signed, content_encoding: "br") }
    assert_raises(Unisender::WebhookError) { verify("\xFF".b) }
  end

  def test_rejects_conflicting_event_keys_and_nonarray_events
    body = payload.sub('"events":[', '"Events":[],"events":[')
    assert_raises(Unisender::WebhookError) { verify(signed(body)) }
    body = payload.sub(/"events":\[.*?\}\]\}/m, '"events":null}')
    assert_raises(Unisender::WebhookError) { verify(signed(body)) }
  end

  def test_rejects_invalid_event_data_and_missing_users
    body = payload.sub('"event_data":{"future":1}', '"event_data":null')
    assert_raises(Unisender::WebhookError) { verify(signed(body)) }
    assert_raises(Unisender::WebhookError) { verify(signed('{"auth":"test-key"}')) }
  end

  def test_event_count_limit_and_error_category
    event = '{"event_name":"x","event_time":"now","event_data":{}}'
    body = %({"auth":"test-key","events_by_user":[{"login":"test","events":[#{event},#{event}]}]})
    error = assert_raises(Unisender::WebhookError) { verify(signed(body), max_events: 1) }
    assert_equal %i[too_many_events invalid_webhook], [error.reason, error.category]
  end

  def test_trailing_gzip_bytes_and_decompression_bound
    compressed = StringIO.new
    Zlib::GzipWriter.wrap(compressed) { |gzip| gzip.write(signed) }
    assert_raises(Unisender::WebhookError) { verify("#{compressed.string}extra", content_encoding: "gzip") }
    assert_raises(Unisender::WebhookError) do
      verify(compressed.string, content_encoding: "gzip", max_decompressed_bytes: 10)
    end
  end

  def test_escaped_top_level_auth_key_and_missing_span
    body = payload.sub('"auth":', '"\\u0061uth":')

    assert_equal 1, verify(signed(body)).events.size
    assert_raises(Unisender::WebhookError) { Unisender::Webhooks.auth_span("{}") }
  end

  def test_duplicate_guard_also_handles_parsers_that_allow_duplicate_keys
    assert_raises(Unisender::WebhookError) do
      Unisender::Webhooks.auth_span('{"auth":"x","nested":{"x":1,"x":2}}')
    end
  end

  def test_unknown_scalar_arrays_remain_intact
    notification = verify(signed(payload(extra: '"future":["one","two"],')))

    assert_equal %w[one two], notification["future"]
  end
end
