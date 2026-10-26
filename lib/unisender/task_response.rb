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
      if completed?
        yield self if block_given?
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
      raise TaskError, self unless status == "completed"

      url = file_to_download
      raise InvalidResponseError, "Missing task download URL" unless url

      downloader.download(url, io, max_bytes:)
    end
  end

  class TaskFailedError < TaskError; end
  class UnknownTaskStateError < TaskError; end

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
