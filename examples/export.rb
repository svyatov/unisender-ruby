# frozen_string_literal: true

# Requires UNISENDER_API_KEY and UNISENDER_LIST_ID. Starts an export job.
# The returned download URL grants access to contact data; keep it private.
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
job = client.export_contacts(list_id: ENV.fetch("UNISENDER_LIST_ID"))
completed = client.wait_for_task(task_uuid: job.result.fetch("task_uuid"))
download_url = completed.result.fetch("file_to_download")
puts "Export ready at host: #{URI(download_url).host}"
