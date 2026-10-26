# frozen_string_literal: true

require "test_helper"
require "unisender/testing"
require "stringio"
require_relative "../scripts/live_contracts"

class LiveContractsTest < Minitest::Test
  def test_explicit_opt_in_and_phase_are_required
    assert_raises(ArgumentError) { LiveContracts.run({}, StringIO.new) }
    assert_raises(ArgumentError) { LiveContracts.run({ "UNISENDER_LIVE" => "1" }, StringIO.new) }
  end

  def test_read_contracts_use_only_queued_read_operations
    transport = Unisender::Testing::Transport.new
    %w[getLists getFields getTags].each { |operation| transport.enqueue(operation:, data: { "result" => [] }) }
    client = Unisender::Client.new(api_key: "test", transport:)
    output = StringIO.new
    LiveContracts.run({ "UNISENDER_LIVE" => "1", "UNISENDER_LIVE_MODE" => "read" }, output, client:)
    transport.verify!

    assert_match(/read contracts passed/, output.string)
  end

  def test_mutation_contracts_remove_only_the_created_list
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "id" => 42 } })
    transport.enqueue(data: { "result" => [{ "id" => 42, "title" => "created" }] })
    transport.enqueue(operation: "deleteList", data: { "result" => [] })
    client = Unisender::Client.new(api_key: "test", transport:)
    LiveContracts.run({ "UNISENDER_LIVE" => "1", "UNISENDER_LIVE_MODE" => "mutation" }, StringIO.new, client:)

    assert_equal "42", transport.requests.last.form["list_id"]
  end

  def test_missing_created_list_still_cleans_up
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "id" => 42 } })
    2.times { transport.enqueue(data: { "result" => [] }) }
    client = Unisender::Client.new(api_key: "test", transport:)
    assert_raises(RuntimeError) { LiveContracts.mutate(client) }
    transport.verify!
  end

  def test_default_client_is_constructed_only_after_opt_in
    transport = Unisender::Testing::Transport.new
    3.times { transport.enqueue(data: { "result" => [] }) }
    client = Unisender::Client.new(api_key: "test", transport:)
    original = Unisender::Client.method(:from_env)
    Unisender::Client.singleton_class.remove_method(:from_env)
    Unisender::Client.define_singleton_method(:from_env) { |**| client }
    LiveContracts.run({ "UNISENDER_LIVE" => "1", "UNISENDER_LIVE_MODE" => "read" }, StringIO.new)
  ensure
    Unisender::Client.singleton_class.remove_method(:from_env)
    Unisender::Client.define_singleton_method(:from_env, original)
  end
end
