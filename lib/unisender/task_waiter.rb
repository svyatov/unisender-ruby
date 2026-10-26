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
      validate!(interval, timeout)
      deadline = @clock.call + timeout
      loop do
        response = @client.get_task_result(task_uuid:)
        @progress&.call(response)
        return response if complete?(response)

        wait(interval, deadline, response)
      end
    end

    private

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

      @sleeper.call([interval, remaining].min)
      raise TaskTimeoutError, response if @clock.call >= deadline
    end
  end
end
