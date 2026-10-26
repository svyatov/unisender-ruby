# frozen_string_literal: true

module Unisender
  # Thread-safe cooperative cancellation. It never interrupts in-flight work.
  class CancellationToken
    def initialize
      @cancelled = false
      @mutex = Mutex.new
    end

    def cancel
      @mutex.synchronize { @cancelled = true }
    end

    def cancelled?
      @mutex.synchronize { @cancelled }
    end
  end

  # Cancellation reached a cooperative boundary.
  class CancelledError < Error
    def category
      :cancelled
    end
  end

  # The shared monotonic budget expired at a cooperative boundary.
  class DeadlineExceededError < Error
    def category
      :deadline_exceeded
    end
  end

  # Separate from request-attempt measurements and free of payloads.
  ExecutionEvent = Data.define(:kind, :operation, :duration, :outcome)

  # One monotonic budget shared by all work in a scoped client.
  class ExecutionContext
    def initialize(timeout: nil, cancellation: nil, parent: nil, instrumentation: nil, clock: nil)
      if timeout && !(timeout.is_a?(Numeric) && timeout.positive? && timeout.finite?)
        raise ArgumentError, "Execution timeout must be positive and finite"
      end

      @clock = clock || -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
      @deadline = @clock.call + Float(timeout) if timeout
      @cancellation = cancellation
      @parent = parent
      @instrumentation = instrumentation
      @closed = false
      @owned_clients = []
    end

    def check!
      raise ClientClosedError, "Execution scope is closed" if @closed

      @parent&.check!
      raise CancelledError, "Execution cancelled" if @cancellation&.cancelled?

      deadline = @deadline
      raise DeadlineExceededError, "Execution deadline exceeded" if deadline && @clock.call >= deadline
    end

    def close
      @closed = true
      @owned_clients.each(&:close)
      @owned_clients.clear
    end

    def own(client)
      @owned_clients << client
    end

    def remaining
      check!
      deadline = @deadline
      values = [deadline ? deadline - @clock.call : nil, @parent&.remaining].compact
      values.min
    end

    def wait(delay, kind, operation, sleeper)
      measure(kind, operation) do
        endpoint = @clock.call + delay
        loop do
          check!
          remaining = endpoint - @clock.call
          break unless remaining.positive?

          sleeper.call([remaining, 0.05].min)
        end
      end
    end

    def measure(kind, operation)
      started = @clock.call
      outcome = :failure
      begin
        result = yield
        outcome = :success
        result
      ensure
        emit(ExecutionEvent.new(kind:, operation: Error.safe_operation(operation) || "workflow",
                                duration: @clock.call - started, outcome:))
      end
    end

    private

    def emit(event)
      @instrumentation&.call(event)
    rescue StandardError
      nil
    end
  end
end
