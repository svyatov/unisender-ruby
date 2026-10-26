# frozen_string_literal: true

module Unisender
  # Explicit helpers for multiple requests.
  class Client
    def each_page(method, page_size: 100, max_pages: 1000, **params, &)
      Iteration.call(Pagination.new(self, method, page_size, max_pages, params).each, &)
    end

    # rubocop:disable-next Metrics/ParameterLists -- Includes the documented import options.
    def import_contacts_in_batches(field_names: nil, data: nil, records: nil, batch_size: 500, overwrite_tags: nil,
                                   overwrite_lists: nil, telegram_bot_channel_id: nil, retention: :full,
                                   on_progress: nil)
      accumulator = BatchAccumulator.new(retention)
      import_batches(field_names:, data:, records:, batch_size:, overwrite_tags:, overwrite_lists:,
                     telegram_bot_channel_id:, accumulator:, on_progress:).each { |_response| nil }
      accumulator.report
    rescue ValidationError => e
      raise e.with_operation("importContacts"), cause: nil
    end

    # rubocop:disable-next Metrics/ParameterLists -- Includes the documented import options.
    def each_import_batch(field_names: nil, data: nil, records: nil, batch_size: 500, overwrite_tags: nil,
                          overwrite_lists: nil, telegram_bot_channel_id: nil, retention: :full, on_progress: nil, &)
      batches = import_batches(field_names:, data:, records:, batch_size:, overwrite_tags:, overwrite_lists:,
                               telegram_bot_channel_id:, retention:, on_progress:)
      Iteration.call(batches, &)
    rescue ValidationError => e
      raise e.with_operation("importContacts"), cause: nil
    end

    # rubocop:disable-next Metrics/ParameterLists -- Shares the batch options without changing public signatures.
    def import_batches(field_names:, data:, records:, batch_size:, overwrite_tags:, overwrite_lists:,
                       telegram_bot_channel_id:, accumulator: nil, retention: :full, on_progress: nil)
      source = import_source(field_names, data, records)
      Batches.each(source, batch_size, 500, accumulator:, retention:, on_progress:, execution: @execution) do |batch|
        names = case source
                when RecordRows then source.field_names
                else field_names
                end
        import_contacts(field_names: names, data: batch, overwrite_tags:, overwrite_lists:, telegram_bot_channel_id:)
      end
    end
    private :import_batches

    def track_events_in_batches(events:, batch_size: 25, retention: :full, on_progress: nil)
      accumulator = BatchAccumulator.new(retention)
      event_batches(events, batch_size, accumulator:, on_progress:).each { |_response| nil }
      accumulator.report
    rescue ValidationError => e
      raise e.with_operation("track_events"), cause: nil
    end

    def each_event_batch(events:, batch_size: 25, retention: :full, on_progress: nil, &)
      Iteration.call(event_batches(events, batch_size, retention:, on_progress:), &)
    rescue ValidationError => e
      raise e.with_operation("track_events"), cause: nil
    end

    def event_batches(events, batch_size, accumulator: nil, retention: :full, on_progress: nil)
      chunks = EventBatches.each(events, batch_size)
      Batches.each_chunks(chunks, accumulator:, retention:, on_progress:, execution: @execution) do |batch|
        track_events(events: batch)
      end
    end
    private :event_batches

    def wait_for_task(task_uuid:, interval: 1, timeout: 60, clock: nil, sleeper: nil, &progress)
      clock ||= -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
      sleeper ||= ->(delay) { sleep(delay) }
      TaskWaiter.new(self, clock:, sleeper:, progress:).call(task_uuid, interval, timeout)
    end

    private

    def import_source(field_names, data, records)
      if records
        raise ValidationError.new(field: "records", code: :conflicting_input) if field_names || data

        return RecordRows.new(records)
      end
      raise ValidationError.new(field: "data", code: :required) unless data

      Validation.required!({ field_names: }, %w[field_names])
      data
    end
  end
end
