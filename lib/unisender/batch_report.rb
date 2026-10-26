# frozen_string_literal: true

module Unisender
  # Completed responses can be inspected repeatedly without repeating requests.
  class BatchReport
    include Enumerable

    attr_reader :responses

    def initialize(responses, error: nil, failed_range: nil, offsets: nil)
      @responses = responses.dup.freeze
      @error = error
      @failed_range = failed_range
      @offsets = offsets&.dup&.freeze
      freeze
    end

    def each(&block)
      return responses.each unless block

      responses.each(&block)
    end

    def complete?
      @error.nil?
    end

    def completed_batches
      responses.size
    end

    def partial?
      !complete? && (!responses.empty? || failed_response&.partial? == true)
    end

    def uncertain?
      error = @error
      case error
      when nil, ArgumentError then false
      when PartialFailure
        response = failed_response
        response.nil? || response.uncertain?
      when EventError then error.report.uncertain?
      else true
      end
    end

    def failures
      response = failed_response
      return [] unless response

      offset = @failed_range&.begin || 0
      response.failures.map { |failure| failure.with_offset(offset) }
    end

    def row_warnings
      # @type var warnings: Array[Failure]
      warnings = []
      # @type var offset: Integer?
      offset = 0
      offsets = @offsets
      responses.each_with_index do |response, index|
        next unless response.is_a?(ImportResponse)

        warnings.concat(warning_rows(response, offsets ? offsets.fetch(index) : offset))
        count = response.total
        offset = offset && count ? offset + count : nil
      end
      warnings + failed_warnings
    end

    def total
      results = import_results
      return nil unless results

      totals = results.map(&:total)
      totals.include?(nil) ? nil : totals.compact.sum
    end

    def invalid
      import_results&.sum(&:invalid)
    end

    private

    def failed_warnings
      failed = failed_response
      failed.is_a?(ImportResponse) ? warning_rows(failed, @failed_range&.begin) : []
    end

    def warning_rows(response, offset)
      response.row_warnings.map do |warning|
        offset ? warning.with_offset(offset) : Failure.new(warning.to_h.merge("index" => nil))
      end
    end

    def failed_response
      error = @error
      return nil unless error.is_a?(PartialFailure)

      response = error.response
      response if response.is_a?(OutcomeResponse)
    end

    def import_results
      return nil if @error && !failed_response

      all = responses.dup
      failed = failed_response
      all << failed if failed
      results = all.filter_map { |response| response.result if response.is_a?(ImportResponse) }
      results if results.size == all.size
    end
  end
end
