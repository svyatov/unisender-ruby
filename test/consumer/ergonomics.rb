# frozen_string_literal: true

require "unisender"
require "unisender/testing"
require "unisender/webhooks"

client = Unisender::Client.from_env(message_defaults: { sender_name: "Example", sender_email: "news@example.test" })
client.get_lists.each { |list| puts list.title }
puts client.get_lists.fetch(0).to_h
puts client.get_contact(email: "person@example.test").email_address
client.unsubscribe(email: "person@example.test", list_ids: [1])
token = Unisender::CancellationToken.new
client.with_execution(timeout: 10, cancellation: token) do |scoped|
  summary = scoped.import_contacts_in_batches(records: [{ email: "person@example.test" }], retention: :summary,
                                              on_progress: ->(progress) { puts progress.next_index })
  puts summary.completed_items
end
client.list_hooks.each { |hook| puts hook.event_format }
transport = Unisender::Testing::Transport.new
transport.verify!
