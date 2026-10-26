# frozen_string_literal: true

module Unisender
  # Explicit helpers for multiple requests.
  class Client
    def each_page(method, page_size: 100, max_pages: 1000, **params)
      Pagination.new(self, method, page_size, max_pages, params).each
    end

    # rubocop:disable-next Metrics/ParameterLists -- Includes the documented import options.
    def import_contacts_in_batches(field_names:, data:, batch_size: 500, overwrite_tags: nil,
                                   overwrite_lists: nil, telegram_bot_channel_id: nil)
      BatchReport.new(each_import_batch(field_names:, data:, batch_size:, overwrite_tags:,
                                        overwrite_lists:, telegram_bot_channel_id:).to_a)
    end

    # rubocop:disable-next Metrics/ParameterLists -- Includes the documented import options.
    def each_import_batch(field_names:, data:, batch_size: 500, overwrite_tags: nil,
                          overwrite_lists: nil, telegram_bot_channel_id: nil, &)
      batches = Batches.each(data, batch_size, 500) do |batch|
        import_contacts(field_names:, data: batch, overwrite_tags:, overwrite_lists:, telegram_bot_channel_id:)
      end
      Iteration.call(batches, &)
    end

    def track_events_in_batches(events:, batch_size: 25)
      BatchReport.new(each_event_batch(events:, batch_size:).to_a)
    end

    def each_event_batch(events:, batch_size: 25, &)
      batches = Batches.each(events, batch_size, 25) { |batch| track_events(events: batch) }
      Iteration.call(batches, &)
    end

    def wait_for_task(task_uuid:, interval: 1, timeout: 60, clock: nil, sleeper: nil)
      clock ||= -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
      sleeper ||= ->(delay) { sleep(delay) }
      TaskWaiter.new(self, clock:, sleeper:).call(task_uuid, interval, timeout) # : Response[task_completed]
    end
  end
end
