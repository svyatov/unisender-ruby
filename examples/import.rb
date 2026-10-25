# frozen_string_literal: true

# Requires UNISENDER_API_KEY and UNISENDER_CONTACT_EMAIL. Changes contacts.
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
begin
  client.import_contacts_in_batches(
    field_names: %w[email Name], data: [[ENV.fetch("UNISENDER_CONTACT_EMAIL"), "Example"]]
  ).each { |response| puts "Imported batch: HTTP #{response.status}" }
rescue Unisender::BatchError => e
  warn "Completed batches: #{e.completed_responses.size}; review rows #{e.failed_range}"
  if e.error.is_a?(Unisender::PartialFailure)
    warn "Some rows in the failed batch were accepted. Inspect error.error.response.result privately."
  end
  warn e.error.message
  # Stop here. Reconcile accepted rows before building a new input; never replay all rows blindly.
end
