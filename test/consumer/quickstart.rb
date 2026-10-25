# frozen_string_literal: true

require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
client.get_lists.result.each { |list| puts list.fetch("title") }
list_id = client.create_list(title: "Product news").result.fetch("id")
client.subscribe(list_ids: [list_id], fields: { email: "person@example.com" })
message_id = client.create_email_message(
  sender_name: "Example", sender_email: "news@example.com", list_id:,
  subject: "Product news", body: "<p>Hello</p>"
).result.fetch("message_id")
client.create_campaign(message_id:)
job = client.export_contacts(list_id:)
completed = client.wait_for_task(task_uuid: job.result.fetch("task_uuid"))
puts completed.result.fetch("file_to_download")
puts client.track_events(events: [{ name: "purchase", email: "person@example.com" }]).result.fetch("success")
