# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class HooksTest < Minitest::Test
  def test_list_hooks_has_typed_readers
    record = { "id" => 3, "url" => "https://example.test/hook", "event_format" => "json_post_gzip",
               "max_parallel" => 10, "single_event" => 0, "status" => "active", "events" => { "subscribe" => ["1"] } }
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [record] })
    hook = Unisender::Client.new(api_key: "test", transport:).list_hooks.first

    assert_equal [3, "https://example.test/hook", "json_post_gzip", 10, 0, "active", ["1"]],
                 [hook.id, hook.url, hook.event_format, hook.max_parallel, hook.single_event, hook.status,
                  hook.events["subscribe"]]
  end

  def test_invalid_hook_inputs_and_response
    client = Unisender::Client.new(api_key: "test")
    assert_raises(Unisender::ValidationError) { client.set_hook(hook_url: "https://example.test", events: {}, max_parallel: 0) }
    assert_raises(Unisender::ValidationError) { client.set_hook(hook_url: "https://example.test", events: []) }
    assert_raises(Unisender::InvalidResponseError) { Unisender::Hook.new({ "id" => 1 }) }
  end

  def test_invalid_hook_event_record
    fields = { "id" => 1, "url" => "https://example.test", "event_format" => "json_post",
               "max_parallel" => 1, "single_event" => 0, "status" => "active", "events" => [] }
    assert_raises(Unisender::InvalidResponseError) { Unisender::Hook.new(fields) }
  end
end
