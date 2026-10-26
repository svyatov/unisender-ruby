# frozen_string_literal: true

module Unisender
  BatchProgress = Data.define(:completed_batches, :completed_items, :next_index, :invalid, :warning_count, :response)

  # Bounded completed-work metadata; only the failing response is retained.
  class BatchSummary
    attr_reader :completed_batches, :completed_items, :invalid, :warning_count

    def initialize(progress, error: nil, failed_range: nil)
      @completed_batches = progress.completed_batches
      @completed_items = progress.completed_items
      @invalid = progress.invalid
      @warning_count = progress.warning_count
      @failure = BatchReport.new([], error:, failed_range:)
      freeze
    end

    def complete?
      @failure.complete?
    end

    def partial?
      !complete? && (completed_batches.positive? || @failure.partial?)
    end

    def uncertain?
      @failure.uncertain?
    end

    def failures
      @failure.failures
    end

    def row_warnings
      @failure.row_warnings
    end
  end

  # Stores source offsets independently from optional upstream counters.
  class BatchAccumulator
    attr_reader :responses, :completed_items

    def initialize(retention)
      raise ValidationError.new(field: "retention", code: :invalid_choice) unless %i[full summary].include?(retention)

      @retention = retention
      @responses = []
      @offsets = []
      @completed_items = 0
      @completed_batches = 0
      @invalid = 0
      @warning_count = 0
    end

    def add(response, count)
      if @retention == :full
        @offsets << @completed_items
        @responses << response
      end
      @completed_items += count
      @completed_batches += 1
      return unless response.is_a?(ImportResponse)

      @invalid += response.invalid
      @warning_count += response.row_warnings.size
    end

    def progress(response: nil)
      BatchProgress.new(completed_batches: @completed_batches, completed_items: @completed_items,
                        next_index: @completed_items, invalid: @invalid, warning_count: @warning_count, response:)
    end

    def report(error: nil, failed_range: nil)
      if @retention == :summary
        BatchSummary.new(progress, error:, failed_range:)
      else
        BatchReport.new(@responses, offsets: @offsets, error:, failed_range:)
      end
    end

    def failure(error, range)
      BatchError.new(completed_responses: @responses, failed_range: range, error:,
                     report: report(error:, failed_range: range))
    end
  end
end
