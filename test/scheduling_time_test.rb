# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class SchedulingTimeTest < Minitest::Test
  # https://www.unisender.com/ru/support/api/messages/createcampaign/
  def test_time_sets_utc_and_minute_precision
    transport = Unisender::Testing::Transport.new
    transport.enqueue(data: { "result" => { "campaign_id" => 1, "status" => "scheduled" } })
    client = Unisender::Client.new(api_key: "test", transport:)
    client.create_campaign(message_id: 1, start_time: Time.new(2026, 11, 1, 12, 30, 59, "+03:00"))

    assert_equal ["2026-11-01 09:30", "UTC"], transport.requests.first.form.values_at("start_time", "timezone")
  end

  def test_string_schedule_keeps_account_timezone
    values = Unisender::Inputs.normalize("createCampaign", { start_time: "2026-11-01 12:30" })

    assert_equal({ start_time: "2026-11-01 12:30" }, values)
    assert_equal({ timezone: "UTC" }, Unisender::Inputs.normalize("createCampaign", { timezone: "UTC" }))
  end

  def test_time_accepts_explicit_utc_and_rejects_conflicting_timezone
    time = Time.utc(2026)

    assert_equal "UTC", Unisender::Inputs.normalize("createCampaign", { start_time: time, timezone: "UTC" })[:timezone]
    error = assert_raises(Unisender::ValidationError) do
      Unisender::Inputs.normalize("createCampaign", { start_time: time, timezone: "Europe/Moscow" })
    end
    assert_equal ["timezone", :conflicting_input], [error.field, error.code]
  end

  def test_workflow_uses_the_same_schedule_normalization
    transport = Unisender::Testing::Transport.new
    transport.enqueue(data: { "result" => { "message_id" => 1 } })
    transport.enqueue(data: { "result" => { "campaign_id" => 1, "status" => "scheduled" } })
    client = Unisender::Client.new(api_key: "test", transport:)
    client.send_campaign(message: { list_id: 1, sender_name: "Example", sender_email: "a@example.test",
                                    subject: "News", body: "News" },
                         campaign: { start_time: Time.utc(2026) })

    assert_equal "UTC", transport.requests.last.form["timezone"]
  end
end
