# frozen_string_literal: true

# Requires UNISENDER_API_KEY and UNISENDER_LIST_ID. Starts an export job.
# The returned download URL grants access to contact data; keep it private.
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
job = client.export_contacts(list_id: ENV.fetch("UNISENDER_LIST_ID"))
completed = job.wait
download_url = completed.result.file_to_download || raise("Missing download URL")
puts "Export ready at host: #{URI(download_url).host}"
