# frozen_string_literal: true

require "test_helper"
require "unisender/testing"
require "tmpdir"
require_relative "../examples/import_recovery"

class ImportRecoveryExampleTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir("unisender-recovery")
    @path = File.join(@directory, "state.json")
    @rows = [{ "id" => "customer-1", "fields" => { "email" => "person@example.test" } }]
    @transport = Unisender::Testing::Transport.new
    @job = RecoverableImport.new(Unisender::Client.new(api_key: "test", transport: @transport), @path)
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_completed_checkpoint_prevents_replay
    @transport.enqueue(data: { "result" => { "total" => 1, "invalid" => 0 } },
                       expected_form: { "field_names[0]" => "email", "data[0][0]" => "person@example.test" })

    assert_equal 1, @job.run(@rows)
    assert_equal 1, @job.run(@rows)
    assert_equal 1, @transport.requests.size
  end

  def test_partial_acceptance_leaves_inflight_ids_for_reconciliation
    @transport.enqueue(data: { "result" => { "total" => 1, "invalid" => 1 } })

    assert_raises(Unisender::PartialFailure) { @job.run(@rows) }
    assert_equal ["customer-1"], JSON.parse(File.read(@path)).fetch("in_flight")
    assert_raises(RuntimeError) { @job.run(@rows) }
  end

  def test_unknown_transport_failure_prevents_restart
    @transport.enqueue_response(Unisender::TimeoutError.new("unknown outcome"))

    assert_raises(Unisender::TimeoutError) { @job.run(@rows) }
    assert_raises(RuntimeError) { @job.run(@rows) }
    assert_equal 1, @transport.requests.size
  end

  def test_source_change_and_corrupt_checkpoint_are_rejected
    @transport.enqueue(data: { "result" => { "total" => 1, "invalid" => 0 } })
    @job.run(@rows)

    assert_raises(RuntimeError) { @job.run([]) }
    File.write(@path, "[]")
    assert_raises(RuntimeError) { @job.run(@rows) }
  end

  def test_invalid_batch_size_and_checkpoint_position_are_local_errors
    assert_raises(ArgumentError) { @job.run(@rows, batch_size: 501) }
    state = { source_digest: Digest::SHA256.hexdigest(JSON.generate(@rows)), next_index: -1 }
    File.write(@path, JSON.generate(state))
    assert_raises(RuntimeError) { @job.run(@rows) }
    assert_empty @transport.requests
  end
end
