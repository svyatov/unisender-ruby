# frozen_string_literal: true

module Unisender
  # Executes one batch at a time; a failure never replays previous batches.
  module Batches
    def self.each(items, size, maximum, &operation)
      raise ArgumentError, "Invalid batch_size" unless size.is_a?(Integer) && size.positive? && size <= maximum

      Enumerator.new do |output|
        # @type var completed: Array[Response]
        completed = []
        items.each_slice(size).with_index do |batch, index|
          response = execute(batch, index * size, completed, &operation)
          completed << response
          output << response
        end
      end
    end

    def self.execute(batch, offset, completed)
      response = yield batch
      result = response.result
      raise PartialFailure, response if result.is_a?(Record) && result["invalid"].to_s.to_i.positive?

      response
    rescue Error, ArgumentError => e
      raise BatchError.new(completed_responses: completed, failed_range: offset...(offset + batch.size), error: e),
            cause: nil
    end
  end
end
