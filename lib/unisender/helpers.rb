# frozen_string_literal: true

module Unisender
  # Explicit helpers for multiple requests.
  class Client
    def each_page(method, page_size: 100, max_pages: 1000, **params, &)
      Iteration.call(Pagination.new(self, method, page_size, max_pages, params).each, &)
    end

    # rubocop:disable-next Metrics/ParameterLists -- Includes the documented import options.
    def import_contacts_in_batches(field_names: nil, data: nil, records: nil, batch_size: 500, overwrite_tags: nil,
                                   overwrite_lists: nil, telegram_bot_channel_id: nil)
      BatchReport.new(each_import_batch(field_names:, data:, records:, batch_size:, overwrite_tags:,
                                        overwrite_lists:, telegram_bot_channel_id:).to_a)
    end

    # rubocop:disable-next Metrics/ParameterLists -- Includes the documented import options.
    def each_import_batch(field_names: nil, data: nil, records: nil, batch_size: 500, overwrite_tags: nil,
                          overwrite_lists: nil, telegram_bot_channel_id: nil, &)
      source = import_source(field_names, data, records)
      batches = Batches.each(source, batch_size, 500) do |batch|
        names = case source
                when RecordRows then source.field_names
                else field_names
                end
        import_contacts(field_names: names, data: batch, overwrite_tags:, overwrite_lists:, telegram_bot_channel_id:)
      end
      Iteration.call(batches, &)
    end

    def track_events_in_batches(events:, batch_size: 25)
      BatchReport.new(each_event_batch(events:, batch_size:).to_a)
    end

    def each_event_batch(events:, batch_size: 25, &)
      chunks = EventBatches.each(events, batch_size)
      batches = Batches.each_chunks(chunks) { |batch| track_events(events: batch) }
      Iteration.call(batches, &)
    end

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
