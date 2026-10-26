# frozen_string_literal: true

# Requires UNISENDER_API_KEY, UNISENDER_LIST_ID, and UNISENDER_CONTACT_EMAIL.
# Changes the account and sends a subscription confirmation email.
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
response = client.subscribe(
  list_ids: [ENV.fetch("UNISENDER_LIST_ID")],
  email: ENV.fetch("UNISENDER_CONTACT_EMAIL")
)
puts response.person_id
