# frozen_string_literal: true

# Requires UNISENDER_API_KEY. Reads lists without printing account data.
require "unisender"

api_key = ENV.fetch("UNISENDER_API_KEY", nil)
abort "Set UNISENDER_API_KEY before running this example." if api_key.nil? || api_key.strip.empty?

begin
  client = Unisender::Client.new(api_key:)
  response = client.get_lists
  puts "Connected to UniSender: HTTP #{response.http_status}, #{response.result.size} list(s)."
rescue ArgumentError, Unisender::Error => e
  warn e.message
  exit 1
end
