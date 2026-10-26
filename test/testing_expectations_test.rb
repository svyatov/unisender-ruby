# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class TestingExpectationsTest < Minitest::Test
  def test_list_and_import_fixtures_decode_through_public_operations
    fixture = Unisender::Testing::Fixtures
    transport = Unisender::Testing::Transport.new
    transport.enqueue(data: { "result" => [fixture.list(id: 1, title: "News")] }, expected_form: { "format" => "json" })
    transport.enqueue(data: { "result" => fixture.import_result(total: 1) })
    client = Unisender::Client.new(api_key: "test", transport:)

    assert_equal "News", client.get_lists.first.title
    assert_predicate client.import_contacts(records: [{ email: "a@example.test" }]), :complete?
  end

  def test_task_and_recipient_fixtures_decode_through_public_operations
    fixture = Unisender::Testing::Fixtures
    transport = Unisender::Testing::Transport.new
    transport.enqueue(data: { "result" => fixture.task(status: "new", task_uuid: "task") })
    transport.enqueue(data: { "result" => [fixture.recipient(index: 0, email: "a@example.test", id: 1)] })
    client = Unisender::Client.new(api_key: "test", transport:)

    assert_equal "task", client.export_contacts(list_id: 1).task_uuid
    assert_equal [1], client.send_email(email: "a@example.test", sender_name: "Shop", sender_email: "b@example.test",
                                        subject: "Hi", body: "Hi", list_id: 1).accepted_ids
  end

  def test_nested_json_subsets_allow_extra_fields
    transport = Unisender::Testing::Transport.new.enqueue(data: { "success" => true },
                                                          expected_json: { "events" => [{ "name" => "sale" }] })
    Unisender::Client.new(api_key: "test", transport:).track_events(events: [{ name: "sale", email: "a@example.test" }])

    assert_same transport, transport.verify!
  end

  def test_mismatch_messages_never_include_values_or_dynamic_keys
    transport = Unisender::Testing::Transport.new.enqueue(data: {}, expected_form: { "private-key" => "private-value" })
    error = assert_raises(RuntimeError) { Unisender::Client.new(api_key: "test", transport:).get_lists }

    refute_match(/private/, error.message)
  end

  def test_expectation_setup_rejects_credentials_and_protocol_conflicts
    transport = Unisender::Testing::Transport.new

    assert_raises(ArgumentError) { transport.enqueue(data: {}, expected_form: { "api_key" => "test" }) }
    assert_raises(ArgumentError) { transport.enqueue(data: {}, expected_form: {}, expected_json: {}) }
  end

  def test_subset_shape_and_value_failures
    [[{}, []], [[], {}], [[], [1]], [{ "a" => 1 }, { "a" => 2 }]].each do |actual, expected|
      assert_raises(RuntimeError) { Unisender::Testing::Assertions.subset!(actual, expected, "json") }
    end
  end

  def test_invalid_json_assertion_omits_body
    request = Unisender::Testing::Request.new(uri: URI("https://example.test"), headers: {}, body: "private")
    error = assert_raises(RuntimeError) { Unisender::Testing::Assertions.check(request, nil, {}) }

    assert_equal "Expected JSON request body", error.message
  end
end
