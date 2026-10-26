# frozen_string_literal: true

module Unisender
  # Polls an existing asynchronous job without starting or downloading an export.
  class TaskWaiter
    PENDING = %w[new processing].freeze

    def initialize(client, clock:, sleeper:, progress: nil)
      @client = client
      @clock = clock
      @sleeper = sleeper
      @progress = progress
    end

    def call(task_uuid, interval, timeout)
      poll(task_uuid, interval, deadline_for(interval, timeout))
    end

    private

    def poll(task_uuid, interval, deadline)
      # @type var last_response: TaskResponse?
      last_response = nil
      loop do
        response = @client.get_task_result(task_uuid:)
        last_response = response
        @progress&.call(response)
        return response if complete?(response)

        wait(interval, deadline, response)
      end
    rescue Error => e
      raise e.with_task(task_uuid:, last_response:), cause: nil
    end

    def deadline_for(interval, timeout)
      validate!(interval, timeout)
      @clock.call + timeout
    end

    def validate!(interval, timeout)
      [interval, timeout].each do |value|
        unless value.is_a?(Numeric) && value.positive? && value.finite?
          raise ArgumentError, "Polling interval and timeout must be positive and finite"
        end
      end
    end

    def complete?(response)
      result = response.result
      return true if result["status"] == "completed"
      raise TaskFailedError, response if result["status"] == "failed"
      raise UnknownTaskStateError, response unless PENDING.include?(result["status"])

      false
    end

    def wait(interval, deadline, response)
      remaining = deadline - @clock.call
      raise TaskTimeoutError, response unless remaining.positive?

      @client.execution_wait([interval, remaining].min, :poll_wait, "async/getTaskResult", @sleeper)
      raise TaskTimeoutError, response if @clock.call >= deadline
    end
  end
end
