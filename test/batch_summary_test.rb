# frozen_string_literal: true

require "test_helper"
require "unisender/testing"
require "stringio"

class BatchSummaryTest < Minitest::Test
  def setup
    @transport = Unisender::Testing::Transport.new
    @client = Unisender::Client.new(api_key: "test", transport: @transport)
    @records = Array.new(3) { { email: "person@example.test" } }
  end

  def test_full_reports_use_source_offsets_without_upstream_totals
    2.times do
      @transport.enqueue(data: { "result" => { "invalid" => 0, "log" => [{ "index" => 0, "code" => "w_x" }] } })
    end
    report = @client.import_contacts_in_batches(records: @records, batch_size: 2)

    assert_equal [0, 2], report.row_warnings.map(&:index)
  end

  def test_summary_counts_and_checkpoints_without_response_history
    2.times { @transport.enqueue(data: { "result" => { "invalid" => 0 } }) }
    progress = []
    report = @client.import_contacts_in_batches(records: @records, batch_size: 2, retention: :summary,
                                                on_progress: progress.method(:push))

    assert_equal [2, 3, 0, true, false, false, [], []],
                 [report.completed_batches, report.completed_items, report.invalid,
                  report.complete?, report.partial?, report.uncertain?, report.failures, report.row_warnings]
    refute_respond_to report, :each
    assert_equal [2, 3], progress.map(&:next_index)
  end

  def test_summary_failure_keeps_only_failed_details
    @transport.enqueue(data: { "result" => { "invalid" => 0 } })
    @transport.enqueue(data: { "result" => { "invalid" => 1, "total" => 1,
                                             "log" => [{ "index" => 0, "code" => "e_x" }] } })
    error = assert_raises(Unisender::BatchError) do
      @client.import_contacts_in_batches(records: @records, batch_size: 2, retention: :summary)
    end
    assert_equal [[], 2...3, [2]], [error.completed_responses, error.failed_range, error.report.failures.map(&:index)]
    assert_equal [true, false], [error.report.partial?, error.report.uncertain?]
  end

  def test_summary_event_batches_and_callback_failure
    @transport.enqueue(data: { "success" => true })
    error = assert_raises(Unisender::BatchError) do
      @client.each_event_batch(events: [{ name: "x", email: "a@b.test" }], retention: :summary,
                               on_progress: ->(_) { raise "checkpoint failed" }).to_a
    end
    assert_equal [1, 1...1], [error.report.completed_batches, error.failed_range]
  end

  def test_invalid_retention
    assert_raises(Unisender::ValidationError) { Unisender::BatchAccumulator.new(:unknown) }
    assert_raises(Unisender::ValidationError) { @client.each_event_batch(events: [], batch_size: 0) }
  end

  def test_reenumerating_replayable_input_repeats_it_with_fresh_accounting
    4.times { @transport.enqueue(data: { "result" => { "invalid" => 0 } }) }
    checkpoints = []
    batches = @client.each_import_batch(records: @records, batch_size: 2,
                                        on_progress: ->(p) { checkpoints << p.next_index })

    assert_equal [2, 2], [batches.to_a.size, batches.to_a.size]
    assert_equal [2, 3, 2, 3], checkpoints
  end

  def test_first_consumption_does_not_rewind_positioned_input
    input = StringIO.new("a\nb\nc\n")
    input.gets
    2.times { @transport.enqueue(data: { "result" => { "invalid" => 0 } }) }
    @client.each_import_batch(field_names: ["email"], data: input.each_line.lazy.map { |row| [row.strip] },
                              batch_size: 1).to_a

    assert_equal(%w[b c], @transport.requests.map { |request| request.form["data[0][0]"] })
  end

  def test_progress_exposes_current_response_without_summary_retaining_it
    @transport.enqueue(data: { "success" => true })
    seen = nil
    @client.track_events_in_batches(events: [{ name: "x", email: "a@b.test" }], retention: :summary,
                                    on_progress: ->(progress) { seen = progress.response })

    assert_instance_of Unisender::EventResponse, seen
  end
end
