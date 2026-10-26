# frozen_string_literal: true

require "unisender"
require "digest"

# Application-owned file checkpoint. Use a private directory and one worker per state file.
class RecoverableImport
  def initialize(client, state_path)
    @client = client
    @state_path = state_path
  end

  def run(rows, batch_size: 500)
    raise ArgumentError, "Invalid batch size" unless (1..500).cover?(batch_size)

    state = read_state(rows)
    offset = resume_index(state, rows.size)
    rows.drop(offset).each_slice(batch_size) { |batch| offset = import_batch(batch, state, offset) }
    offset
  end

  private

  def resume_index(state, size)
    raise "Reconcile the recorded in-flight rows before resuming" if state["in_flight"]

    offset = state.fetch("next_index")
    raise "Invalid checkpoint index" unless offset.is_a?(Integer) && (0..size).cover?(offset)

    offset
  end

  def import_batch(batch, state, offset)
    state["in_flight"] = batch.map { |row| row.fetch("id") }
    save(state) # Durable intent precedes the remote mutation.
    records = batch.map { |row| row.fetch("fields") }
    @client.import_contacts(records:).raise_for_partial_failure!
    state["next_index"] = offset + batch.size
    state.delete("in_flight")
    save(state) # Crash before this write requires reconciliation, not replay.
    offset + batch.size
  end

  def read_state(rows)
    digest = Digest::SHA256.hexdigest(JSON.generate(rows))
    return { "source_digest" => digest, "next_index" => 0 } unless File.exist?(@state_path)

    state = JSON.parse(File.read(@state_path)) # : Unisender::json
    raise "Invalid checkpoint" unless state.is_a?(Hash)
    raise "Source changed; reconcile before resuming" unless state["source_digest"] == digest

    state
  end

  def save(state)
    temporary = "#{@state_path}.#{Process.pid}.tmp"
    File.open(temporary, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
      file.write(JSON.generate(state))
      file.flush
      file.fsync
    end
    File.rename(temporary, @state_path)
    File.open(File.dirname(@state_path), &:fsync)
  end
end
