# frozen_string_literal: true

# Requires the API key, list ID, sender email, test email, and ISO 8601 start time below.
# Creates a message, sends a test, and schedules a campaign to consenting test recipients.
# Stop on failure. Reconcile saved IDs before rerunning any mutation.
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
list_id = ENV.fetch("UNISENDER_LIST_ID")
sender = ENV.fetch("UNISENDER_SENDER_EMAIL")
test_email = ENV.fetch("UNISENDER_TEST_EMAIL")
start_time = Time.iso8601(ENV.fetch("UNISENDER_START_TIME"))
raise ArgumentError, "Choose a future start time" unless start_time > Time.now

# 1. Creates message content, without launching the campaign.
message = client.create_email_message(sender_name: "Example", sender_email: sender,
                                      list_id:, subject: "Product news", body: "<p>Hello</p>")
puts "Save message_id: #{message.message_id}"
# 2. Reads the created content. Save the ID in application storage before continuing.
draft = client.get_message(id: message.message_id)
puts "Review subject: #{draft.subject}"
# 3. Sends only to the explicit test address. The provider can require address verification.
client.send_test_email(id: message.message_id, email: test_email)
# 4. Schedules delivery to the list. Time is converted to explicit UTC, at minute precision.
campaign = client.create_campaign(message_id: message.message_id, start_time:)
puts "Save campaign_id: #{campaign.campaign_id}"
# 5. Reads status once. Repeat only this read when observing the same campaign.
puts "Campaign status: #{client.get_campaign_status(campaign_id: campaign.campaign_id).status}"
