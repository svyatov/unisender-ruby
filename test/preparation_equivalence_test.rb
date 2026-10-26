# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class PreparationEquivalenceTest < Minitest::Test
  def test_paginated_validation_matches_execution_for_false_controls
    paginated_fixtures.each do |item|
      name = item.fetch("name").to_sym
      params = item.fetch("args").transform_keys(&:to_sym).merge(limit: false)
      client = Unisender::Client.new(api_key: "test", transport: Unisender::Testing::Transport.new)

      assert_matching_diagnostics(client, name, params)
    end
  end

  def test_import_missing_matrix_fields_match_execution
    client = Unisender::Client.new(api_key: "test", transport: Unisender::Testing::Transport.new)
    [{}, { field_names: [], data: [] }, { field_names: ["email"], data: nil }].each do |params|
      before = assert_raises(Unisender::ValidationError) { client.validate!(:import_contacts, **params) }
      actual = assert_raises(Unisender::ValidationError) { client.import_contacts(**params) }

      assert_equal before.diagnostics, actual.diagnostics
    end
  end

  def test_result_container_errors_include_http_and_shape
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => {} }, headers: { "x-request-id" => "r1" })
    error = assert_raises(Unisender::InvalidResponseError) do
      Unisender::Client.new(api_key: "test", transport:).get_lists
    end

    assert_equal ["result", "Array", "Hash", 200, "r1"],
                 [error.path, error.expected_type, error.actual_type, error.http_status, error.request_id]
  end

  def test_event_indices_and_types_agree_without_networking
    client = Unisender::Client.new(api_key: "test", transport: Unisender::Testing::Transport.new)
    events = [{ name: "sale", email: "a@example.test" }, { name: false, email: "b@example.test" }]
    before = assert_raises(Unisender::ValidationError) { client.validate!(:track_events, events:) }
    actual = assert_raises(Unisender::ValidationError) { client.track_events(events:) }

    assert_equal ["events[1].name", "String", "Boolean", before.diagnostics],
                 [actual.path, actual.expected_type, actual.actual_type, actual.diagnostics]
  end

  def test_event_keyword_guard_and_container_type
    client = Unisender::Client.new(api_key: "test", transport: Unisender::Testing::Transport.new)

    assert_raises(Unisender::ValidationError) { client.validate!(:track_events, events: [], extra: true) }
    assert_matching_diagnostics(client, :track_events, { events: false })
  end

  def test_dynamic_event_keys_cannot_inject_path_syntax
    client = Unisender::Client.new(api_key: "test", transport: Unisender::Testing::Transport.new)
    event = { name: "sale", email: "a@example.test", "email[123456789]SECRET" => Object.new }
    error = assert_raises(Unisender::ValidationError) { client.track_events(events: [event]) }

    assert_equal "events[0].*", error.path
    assert_equal "fields[*]", Unisender::Diagnostics.input_path("fields[0]SECRET")
  end

  def test_tabular_error_locations
    [[[], "result"], [{ "data" => [] }, "result.fields"],
     [{ "fields" => [], "data" => nil }, "result.data"],
     [{ "fields" => %w[url url], "data" => [] }, "result.fields"],
     [{ "fields" => [false], "data" => [] }, "result.fields[0]"]].each do |result, path|
      transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => result })
      error = assert_raises(Unisender::InvalidResponseError) do
        Unisender::Client.new(api_key: "test", transport:).get_visited_links(campaign_id: 1)
      end

      assert_equal path, error.path
    end
  end

  private

  def paginated_fixtures
    JSON.parse(File.read(File.join(__dir__, "fixtures/operations.json")))
        .select { |item| Unisender::PaginatedOperations.supports?(item.fetch("name")) }
  end

  def assert_matching_diagnostics(client, name, params)
    before = assert_raises(Unisender::ValidationError) { client.validate!(name, **params) }
    actual = assert_raises(Unisender::ValidationError) { client.public_send(name, **params) }

    assert_equal before.diagnostics, actual.diagnostics
  end
end
