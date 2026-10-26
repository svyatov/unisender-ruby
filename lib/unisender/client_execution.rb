# frozen_string_literal: true

module Unisender
  # Scoped execution shares the original client's transport and lifetime.
  class Client
    def with_execution(timeout: nil, cancellation: nil, instrumentation: nil)
      context = ExecutionContext.new(timeout:, cancellation:, instrumentation:, parent: @execution)
      scoped = execution_client(context)
      begin
        context.measure(:workflow, "workflow") { yield scoped }
      ensure
        context.close
      end
    end

    # Shared by helpers so waits observe the same budget as requests.
    def execution_wait(delay, kind, operation, sleeper)
      context = @execution
      if context
        context.wait(delay, kind, operation, sleeper)
      else
        sleeper.call(delay)
      end
    end

    def check_execution!
      @configuration.check_open!
      @execution&.check!
    end

    def execution_context
      @execution
    end

    protected

    def execution_client(context)
      client = dup
      client.instance_variable_set(:@execution, context)
      client.freeze
    end
  end
end
