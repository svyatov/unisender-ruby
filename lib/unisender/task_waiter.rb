# frozen_string_literal: true

module Unisender
  # Polls an existing asynchronous job without starting or downloading an export.
  class TaskWaiter
    PENDING = %w[new processing].freeze

    def initialize(client, clock:, sleeper:)
      @client = client
      @clock = clock
      @sleeper = sleeper
    end

    def call(task_uuid, interval, timeout)
      validate!(interval, timeout)
      deadline = @clock.call + timeout
      loop do
        response = @client.get_task_result(task_uuid:)
        return response if complete?(response)

        wait(interval, deadline)
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
      raise TaskError, response unless result.is_a?(Hash)
      return true if result["status"] == "completed"
      raise TaskError, response unless PENDING.include?(result["status"])

      false
    end

    def wait(interval, deadline)
      remaining = deadline - @clock.call
      raise TimeoutError, "Timed out waiting for the UniSender task" unless remaining.positive?

      @sleeper.call([interval, remaining].min)
      raise TimeoutError, "Timed out waiting for the UniSender task" if @clock.call >= deadline
    end
  end
end
