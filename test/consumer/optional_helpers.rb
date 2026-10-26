# frozen_string_literal: true

require "unisender"
require "stringio"

client = Unisender::Client.from_env(persistent: true, rate_limiter: Unisender::RateLimiter.unisender)
client.get_lists.each { |list| puts list.title }
puts client.import_contacts(records: [{ email: "person@example.test" }]).inserted
client.each_message(date_from: Time.utc(2026, 1, 1), date_to: Time.utc(2026, 1, 2)).each { |message| puts message.id }
variant = client.with(message_defaults: { sender_name: "Example", sender_email: "news@example.test" })
attachment = Unisender::Attachment.from_io(StringIO.new("bytes"), filename: "example.txt")
receipt = variant.send_campaign(message: { list_id: 1, subject: "News", body: "Hello", attachments: attachment })
puts receipt.campaign.campaign_id
completed = variant.export_contacts.wait
download = completed.download_to(StringIO.new, max_bytes: 1024)
puts download.bytes_written
variant.close
client.close
