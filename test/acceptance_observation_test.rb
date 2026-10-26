# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

# rubocop:disable-next Metrics/ClassLength -- Covers acceptance across all four supported operation families.
class AcceptanceObservationTest < Minitest::Test
  def setup
    @events = []
    @attempts = []
    @transport = Unisender::Testing::Transport.new
    @client = Unisender::Client.from_env(env: { "UNISENDER_API_KEY" => "private" }, transport: @transport,
                                         instrumentation: ->(event) { @attempts << event },
                                         acceptance_instrumentation: ->(event) { @events << event })
  end

  # rubocop:disable-next Minitest/MultipleAssertions -- Verify the complete payload-free observation contract.
  def test_request_success_can_mean_recipient_rejection
    mail([{ "email" => "private@example.test", "errors" => [{ "code" => "invalid" }] }])

    assert_equal :success, @attempts.last.outcome
    assert_event :rejected, 1, 0, 1, 0
    refute_includes @events.last.inspect, "private"
    assert_equal "request-1", @events.last.request_id
    assert_predicate @events.last, :frozen?
  end

  def test_partial_unknown_and_legacy_mail_outcomes
    mail([{ "id" => 1 }, { "errors" => [{ "code" => "invalid" }] }], cc: "cc@example.test")

    assert_event :partial, 2, 1, 1, 0
    mail([{}])

    assert_event :uncertain, 1, 0, 0, 1
    mail({ "email_id" => 2 })

    assert_event :complete, 1, 1, 0, 0
  end

  def test_import_counts_and_row_warnings
    @transport.enqueue(data: { "result" => { "total" => 2, "invalid" => 1,
                                             "log" => [{ "index" => 0, "code" => "w_changed" }] } })
    @client.import_contacts(field_names: ["email"], data: [["a@example.test"], ["bad"]])

    assert_event :partial, 2, 1, 1, 0
    assert_equal 1, @events.last.row_warning_count
    @transport.enqueue(data: { "result" => { "invalid" => 1 } })
    @client.import_contacts(field_names: ["email"], data: [["bad"]])

    assert_event :uncertain, 1, nil, 1, nil
  end

  def test_inconsistent_import_counts_remain_unknown
    @transport.enqueue(data: { "result" => { "total" => 0, "invalid" => 1 } })
    @client.import_contacts(field_names: ["email"], data: [["bad"]])

    assert_event :uncertain, 1, nil, nil, nil
  end

  def test_excess_receipt_counts_are_unknown
    mail([{ "id" => 1 }, { "id" => 2 }])

    assert_event :uncertain, 1, nil, nil, nil
  end

  def test_negative_import_counts_are_unknown
    @transport.enqueue(data: { "result" => { "total" => 1, "invalid" => -1 } })
    @client.import_contacts(records: [{ email: "a@example.test" }])

    assert_event :uncertain, 1, nil, nil, nil
  end

  def test_missing_recipient_or_import_counts_prevent_complete_outcome
    mail([{ "id" => 1 }], cc: "cc@example.test")

    assert_event :uncertain, 2, 1, 0, 1
    @transport.enqueue(data: { "result" => { "total" => 1, "invalid" => 0 } })
    @client.import_contacts(field_names: ["email"], data: [["a@example.test"], ["b@example.test"]])

    assert_event :uncertain, 2, 1, 0, 1
  end

  def test_sms_and_events
    @transport.enqueue(data: { "result" => { "sms_id" => 1, "price" => 1, "currency" => "RUB" } })
    @client.send_sms(phone: ["79000000000"], sender: "Shop", text: "Hi")

    assert_event :complete, 1, 1, 0, 0
    @transport.enqueue(data: { "result" => [] })
    @client.send_sms(phone: ["79000000000"], sender: "Shop", text: "Hi")

    assert_event :uncertain, 1, 0, 0, 1
    @transport.enqueue(data: { "success" => true })
    @client.with.track_events(events: [{ name: "sale", email: "a@example.test" }])

    assert_event :complete, 1, 1, 0, 0
  end

  def test_event_failures_do_not_invent_acceptance
    [401, 400].each do |status|
      @transport.enqueue(data: { "success" => false }, http_status: status)
      assert_raises(Unisender::EventError) do
        @client.track_events(events: [{ name: "sale", email: "a@example.test" }])
      end
      status == 401 ? assert_event(:rejected, 1, 0, 1, 0) : assert_event(:uncertain, 1, nil, nil, nil)
    end
  end

  def test_transport_failure_keeps_counts_unknown
    @transport.enqueue_response(RuntimeError.new("private"))
    assert_raises(RuntimeError) { send_mail }
    assert_event :uncertain, 1, nil, nil, nil
    assert_nil @events.last.row_warning_count
  end

  def test_reads_validation_and_observer_errors
    @transport.enqueue(data: { "result" => [] })
    @client.get_lists
    @client.validate!(:get_lists)

    assert_empty @events
    @transport.enqueue(data: { "result" => { "email_id" => 1 } })
    client = @client.with(acceptance_instrumentation: ->(_event) { raise "observer error" })

    assert_equal 1, send_mail(client:).email_id
  end

  def test_internal_count_guards
    assert_nil Unisender::Acceptance.input_count("sendSms", {})
    assert_nil Unisender::Acceptance.input_count("importContacts", {})
  end

  private

  def mail(result, **)
    @transport.enqueue(data: { "result" => result }, headers: { "x-request-id" => "request-1" })
    send_mail(**)
  end

  def send_mail(client: @client, **)
    client.send_email(email: "a@example.test", sender_name: "Shop", sender_email: "b@example.test",
                      subject: "Hi", body: "Hi", list_id: 1, **)
  end

  def assert_event(outcome, input, accepted, rejected, unknown)
    event = @events.last

    assert_equal [outcome, input, accepted, rejected, unknown],
                 [event.outcome, event.input_count, event.accepted_count, event.rejected_count, event.unknown_count]
  end
end
