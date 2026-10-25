# frozen_string_literal: true

# Requires UNISENDER_API_KEY and UNISENDER_CONTACT_EMAIL.
# Records an event and can trigger account automation.
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
begin
  client.track_events_in_batches(events: [
                                   { name: "purchase", email: ENV.fetch("UNISENDER_CONTACT_EMAIL"), total: 1200,
                                     currency: "RUB" }
                                 ]).each { |response| puts "Recorded batch: HTTP #{response.status}" }
rescue Unisender::BatchError => e
  warn "Review events #{e.failed_range}; completed batches: #{e.completed_responses.size}"
  failure = e.error
  if failure.is_a?(Unisender::EventError) && failure.possibly_partially_accepted?
    warn "Valid events may already be accepted. Inspect failure.details privately before retrying."
  end
  warn failure.message
end
