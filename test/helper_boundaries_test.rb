# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class HelperBoundariesTest < Minitest::Test
  def setup
    @transport = ScriptedTransport.new
    @client = Unisender::Client.new(api_key: "test-key", transport: @transport)
  end

  def test_invalid_pagination_options_do_not_send_requests
    [{ page_size: 0 }, { page_size: "2" }, { page_size: 101 }, { max_pages: 0 }, { offset: -1 },
     { offset: "0" }, { limit: 1 }].each do |options|
      assert_raises(ArgumentError) { @client.each_page(:get_templates, **options).to_a }
    end
    assert_raises(ArgumentError) { @client.each_page(:get_lists).to_a }
    assert_raises(ArgumentError) { @client.each_page(:get_campaigns).to_a }
  end

  def test_stops_at_the_page_limit
    client = client_for([1])

    assert_raises(Unisender::PaginationError) { client.each_page(:get_templates, page_size: 1, max_pages: 1).to_a }
  end

  def test_empty_pages_and_early_stopping
    assert_equal [[]], client_for([]).each_page(:get_templates).map(&:result)
    assert_equal [[1]], client_for([1]).each_page(:get_templates, page_size: 1).take(1).map(&:result)
    assert_equal [[]], client_for([]).each_page(:get_subscriber_notes, subscriber_id: 1).map(&:result)
  end

  def test_counts_domains_inside_the_documented_groups
    value = [{ "domains" => [{ "Domain" => "example.test" }] }]

    assert_equal [value], client_for(value).each_page(:get_sender_domain_list, username: "ID1").map(&:result)
  end

  def test_rejects_malformed_page_shapes
    assert_raises(Unisender::InvalidResponseError) { client_for({}).each_page(:get_templates).to_a }
    [1, {}].each do |group|
      assert_raises(Unisender::InvalidResponseError) do
        client_for([group]).each_page(:get_sender_domain_list, username: "ID1").to_a
      end
    end
  end

  def test_rejects_invalid_batch_sizes
    [0, 501, "2"].each do |size|
      assert_raises(ArgumentError) do
        @client.import_contacts_in_batches(field_names: ["email"], data: [], batch_size: size)
      end
    end
    assert_raises(ArgumentError) { @client.track_events_in_batches(events: [], batch_size: 26) }
    assert_empty @client.track_events_in_batches(events: []).to_a
  end

  def test_partial_import_failure_is_available_without_replaying
    client = client_for({ "invalid" => 1, "log" => ["fake failure"] })
    error = assert_raises(Unisender::BatchError) do
      client.import_contacts_in_batches(field_names: ["email"], data: [["a@example.test"]]).to_a
    end

    assert_instance_of Unisender::PartialFailure, error.error
    assert_equal({ "invalid" => 1, "log" => ["fake failure"] }, error.error.response.result)
  end

  def test_event_success_without_success_flag_is_malformed
    [false, nil].each do |success|
      transport = ScriptedTransport.new(ScriptedTransport.reply({ "success" => success }))
      client = Unisender::Client.new(api_key: "test-key", transport:)

      assert_raises(Unisender::InvalidResponseError) { client.track_events(events: [{ name: "sale", email: "a@b.test" }]) }
    end
  end

  def test_rejects_cyclic_event_payloads
    event = { name: "sale", email: "a@b.test" }
    event[:extra] = event

    assert_raises(ArgumentError) { @client.track_events(events: [event]) }
  end

  def test_default_polling_and_terminal_errors
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => { "status" => "processing" } }),
                                      ScriptedTransport.reply({ "result" => { "status" => "completed" } }))
    client = Unisender::Client.new(api_key: "test-key", transport:)

    assert_equal "completed", client.wait_for_task(task_uuid: "task", interval: 0.001).result["status"]
    [{ "status" => "failed" }, []].each do |result|
      assert_raises(Unisender::TaskError) { client_for(result).wait_for_task(task_uuid: "task") }
    end
  end

  def test_poll_deadlines_and_invalid_timeouts
    [0, -1, Float::INFINITY, "1"].each do |timeout|
      assert_raises(ArgumentError) { @client.wait_for_task(task_uuid: "task", timeout:) }
    end
    assert_poll_timeout(->(time) { time }, ->(time, delay) { time + delay })
    assert_poll_timeout(->(_time) { 100 }, ->(time, _delay) { time })
  end

  private

  def assert_poll_timeout(clock, sleeper)
    time = 0.0
    calls = 0
    client = client_for({ "status" => "processing" })
    assert_raises(Unisender::TimeoutError) do
      client.wait_for_task(task_uuid: "task", timeout: 1, clock: lambda {
        calls += 1
        calls == 1 ? 0 : clock.call(time)
      },
                           sleeper: ->(delay) { time = sleeper.call(time, delay) })
    end
  end

  def client_for(result)
    Unisender::Client.new(api_key: "test-key",
                          transport: ScriptedTransport.new(ScriptedTransport.reply({ "result" => result })))
  end
end
