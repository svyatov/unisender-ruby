# frozen_string_literal: true

require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
client.get_lists.result.each { |list| puts list.fetch("title") }
# Example output for a list named News: News
