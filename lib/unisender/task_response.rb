# frozen_string_literal: true

module Unisender
  # A task handle polls only when the caller requests it.
  class TaskResponse < TaskResultResponse
    attr_reader :task_uuid

    def initialize(response, client:, task_uuid:)
      @client = client
      @task_uuid = task_uuid.dup.freeze
      super(data: response.data, status: response.http_status, headers: response.headers, result: response.result)
    end

    def wait(interval: 1, timeout: 60, clock: nil, sleeper: nil, &)
      if completed? || failed?
        yield self if block_given?
        raise TaskFailedError.new(self).with_task(task_uuid:, last_response: self) if failed?

        return self
      end

      @client.wait_for_task(task_uuid:, interval:, timeout:, clock:, sleeper:, &)
    end

    def completed?
      status == "completed"
    end

    def failed?
      status == "failed"
    end

    def pending?
      TaskWaiter::PENDING.include?(status)
    end

    def download_to(io, max_bytes:, downloader: Downloader.new)
      @client.check_execution!
      raise TaskError, self unless status == "completed"

      url = file_to_download
      raise InvalidResponseError, "Missing task download URL" unless url

      download_file(url, io, max_bytes, downloader)
    end

    private

    def download_file(url, io, max_bytes, downloader)
      case downloader
      when Downloader
        # rubocop:disable-next Style/ClassEqualityComparison -- Preserve custom subclass types in Steep's fallback.
        if downloader.class == Downloader
          return downloader.download(url, io, max_bytes:, execution: @client.execution_context)
        end
      end
      downloader.download(url, io, max_bytes:)
    end
  end

  # A task reached the failed terminal state.
  class TaskFailedError < TaskError
    def category
      :task_failed
    end
  end

  # A task returned a state not documented by the protocol.
  class UnknownTaskStateError < TaskError
    def category
      :unknown_task_state
    end
  end

  # A polling deadline retains the last known task state.
  class TaskTimeoutError < TimeoutError
    attr_reader :response, :task_uuid

    def initialize(response)
      @response = response
      @task_uuid = response.task_uuid
      super("Timed out waiting for the UniSender task")
    end
  end
end
