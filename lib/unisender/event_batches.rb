# frozen_string_literal: true

module Unisender
  # Chooses request boundaries before sending any event in a chunk.
  module EventBatches
    def self.each(events, size)
      Batches.validate_size(size, 25)
      Enumerator.new { |output| build(events, size, output) }
    end

    def self.build(events, size, output)
      # @type var batch: Array[params]
      batch = []
      events.each_with_index do |event, index|
        validate(event, index)
        batch = append(batch, event, size, output)
      end
      output << batch unless batch.empty?
    end

    def self.append(batch, event, size, output)
      if EventPayload.serialize(batch + [event]).bytesize > EventPayload::MAX_BYTES
        output << batch
        batch = [] # : Array[params]
      end
      batch << event
      return batch unless batch.size == size

      output << batch
      []
    end

    def self.validate(event, index)
      EventPayload.encode([event])
    rescue ArgumentError
      raise ValidationError.new(field: "events[#{index}]", code: :invalid_event, operation: "track_events", index:),
            cause: nil
    end
  end
end
