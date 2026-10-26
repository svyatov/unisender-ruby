# frozen_string_literal: true

module Unisender
  # Completed responses can be inspected repeatedly without repeating requests.
  class BatchReport
    include Enumerable

    attr_reader :responses

    def initialize(responses)
      @responses = responses.dup.freeze
      freeze
    end

    def each(&block)
      return responses.each unless block

      responses.each(&block)
    end

    def complete?
      true
    end

    def completed_batches
      responses.size
    end
  end
end
