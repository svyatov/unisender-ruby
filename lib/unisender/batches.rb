# frozen_string_literal: true

module Unisender
  # Executes one batch at a time; a failure never replays previous batches.
  module Batches
    # rubocop:disable-next Metrics/ParameterLists -- Shared explicit batch controls.
    def self.each(items, size, maximum, accumulator: nil, retention: :full, on_progress: nil, execution: nil, &)
      validate_size(size, maximum)
      each_chunks(items.each_slice(size), accumulator:, retention:, on_progress:, execution:, &)
    end

    # rubocop:disable-next Metrics/MethodLength -- Keep accounting next to the yielding boundary.
    def self.each_chunks(chunks, accumulator: nil, retention: :full, on_progress: nil, execution: nil, &operation)
      Enumerator.new do |output|
        state = accumulator || BatchAccumulator.new(retention)
        cursor = chunks.to_enum
        offset = 0
        while (batch = next_chunk(cursor, offset, state, execution))
          response = execute(batch, offset, state, &operation)
          state.add(response, batch.size)
          offset += batch.size
          progress(on_progress, state, offset, response)
          output << response
        end
      end
    end

    def self.validate_size(size, maximum)
      return if size.is_a?(Integer) && size.positive? && size <= maximum

      raise ValidationError.new(field: "batch_size", code: :invalid_range)
    end

    def self.next_chunk(chunks, offset, accumulator, execution)
      execution&.check!
      chunks.next
    rescue StopIteration
      nil
    rescue StandardError => e
      position = e.is_a?(ValidationError) ? e.index : nil
      endpoint = position ? position + 1 : offset
      raise accumulator.failure(e, offset...endpoint), cause: nil
    end

    def self.execute(batch, offset, accumulator)
      response = yield batch
      raise PartialFailure, response if response.is_a?(OutcomeResponse) && !response.complete?

      response
    rescue Error, ArgumentError => e
      raise accumulator.failure(e, offset...(offset + batch.size)), cause: nil
    end

    def self.progress(callback, accumulator, offset, response)
      callback&.call(accumulator.progress(response:))
    rescue StandardError => e
      raise accumulator.failure(e, offset...offset), cause: nil
    end
  end
end
