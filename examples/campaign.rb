# frozen_string_literal: true

# Requires UNISENDER_API_KEY, UNISENDER_LIST_ID, and UNISENDER_SENDER_EMAIL.
# Sends a campaign to the list. Use a verified sender and a list of consenting test recipients.
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
message = client.create_email_message(
  sender_name: "Example", sender_email: ENV.fetch("UNISENDER_SENDER_EMAIL"),
  list_id: ENV.fetch("UNISENDER_LIST_ID"), subject: "Product news", body: "<p>Hello</p>"
)
campaign = client.create_campaign(message_id: message.result.fetch("message_id"))
puts campaign.result.fetch("campaign_id")
