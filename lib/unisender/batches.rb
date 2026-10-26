# frozen_string_literal: true

module Unisender
  # Executes one batch at a time; a failure never replays previous batches.
  module Batches
    def self.each(items, size, maximum, &)
      validate_size(size, maximum)
      each_chunks(items.each_slice(size), &)
    end

    def self.each_chunks(chunks, &operation)
      Enumerator.new do |output|
        # @type var completed: Array[Response]
        completed = []
        offset = 0
        while (batch = next_chunk(chunks, offset, completed))
          response = execute(batch, offset, completed, &operation)
          completed << response
          offset += batch.size
          output << response
        end
      end
    end

    def self.validate_size(size, maximum)
      raise ArgumentError, "Invalid batch_size" unless size.is_a?(Integer) && size.positive? && size <= maximum
    end

    def self.next_chunk(chunks, offset, completed)
      chunks.next
    rescue StopIteration
      nil
    rescue Error, ArgumentError => e
      position = e.is_a?(ValidationError) ? e.index : nil
      endpoint = position ? position + 1 : offset
      raise BatchError.new(completed_responses: completed, failed_range: offset...endpoint, error: e), cause: nil
    end

    def self.execute(batch, offset, completed)
      response = yield batch
      raise PartialFailure, response if response.is_a?(OutcomeResponse) && !response.complete?

      response
    rescue Error, ArgumentError => e
      raise BatchError.new(completed_responses: completed, failed_range: offset...(offset + batch.size), error: e),
            cause: nil
    end
  end
end
