# frozen_string_literal: true

require "unisender"
require "securerandom"

# Explicit staging-only protocol probes. No credentials or payloads are printed.
module LiveContracts
  def self.run(env, output, client: nil)
    raise ArgumentError, "Set UNISENDER_LIVE=1 for a designated test account" unless env["UNISENDER_LIVE"] == "1"

    mode = env["UNISENDER_LIVE_MODE"]
    raise ArgumentError, "Choose read or mutation mode" unless %w[read mutation].include?(mode)

    client ||= Unisender::Client.from_env(env:)
    begin
      mode == "read" ? read(client) : mutate(client)
      output.puts("#{mode} contracts passed on Ruby #{RUBY_VERSION}")
    ensure
      client.close
    end
  end

  def self.read(client)
    client.get_lists.each(&:id)
    client.get_fields.each(&:name)
    client.get_tags.each(&:id)
  end

  def self.mutate(client)
    list = client.create_list(title: "SDK contract #{SecureRandom.hex(8)}")
    begin
      raise "Created list was not returned" unless client.get_lists.any? { |item| item.id == list.id }
    ensure
      client.delete_list(list_id: list.id)
    end
  end
end
