# frozen_string_literal: true

# Requires UNISENDER_API_KEY, UNISENDER_LIST_ID, UNISENDER_EXPORT_STATE,
# and UNISENDER_EXPORT_PATH. Starts or resumes an export job.
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
state = ENV.fetch("UNISENDER_EXPORT_STATE")
destination = ENV.fetch("UNISENDER_EXPORT_PATH")
if File.exist?(state)
  job = client.get_task_result(task_uuid: File.read(state).strip)
else
  job = client.export_contacts(list_id: ENV.fetch("UNISENDER_LIST_ID"))
  File.open("#{state}.tmp", "w", 0o600) { |file| file.write(job.task_uuid) }
  File.rename("#{state}.tmp", state)
end
# A crash before saving the UUID requires reconciliation before starting another job.
completed = job.wait
File.open("#{destination}.part", "wb", 0o600) do |file|
  completed.download_to(file, max_bytes: 100 * 1024 * 1024)
end
File.rename("#{destination}.part", destination)
File.delete(state)
puts "Export saved"
# On failure, keep the UUID. A retry truncates .part and downloads the same job.
