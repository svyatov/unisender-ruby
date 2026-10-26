# frozen_string_literal: true

module Unisender
  # Process-local sliding windows; share an instance across clients using one budget.
  class RateLimiter
    # https://www.unisender.com/ru/support/api/common/api-limits/
    # @type var defaults: Hash[String, [Integer, duration]]
    defaults = {
      "subscribe" => [300, 60], "async/exportContacts" => [20, 60], "getContactCount" => [60, 60],
      "createCampaign" => [100, 60], "checkEmail" => [300, 60], "sendEmail" => [60, 60], "sendSms" => [300, 60]
    }
    DEFAULT_METHODS = defaults.freeze

    def self.unisender(clock: nil, sleeper: nil)
      new(global: [1200, 60], methods: DEFAULT_METHODS, clock:, sleeper:)
    end

    def initialize(global:, methods: {}, clock: nil, sleeper: nil)
      @limits = { "*" => validate(global) }.merge(methods.transform_values { |limit| validate(limit) }).freeze
      @history = @limits.to_h { |name, _| [name, []] }
      @clock = clock || -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
      @sleeper = sleeper || ->(seconds) { sleep(seconds) }
      @mutex = Mutex.new
    end

    def acquire(operation, execution: nil)
      loop do
        execution&.check!
        delay = @mutex.synchronize { reserve(operation) }
        return if delay.zero?

        if execution
          execution.wait(delay, :rate_limit_wait, operation, @sleeper)
        else
          @sleeper.call(delay)
        end
      end
    end

    def inspect
      "#<Unisender::RateLimiter>"
    end

    private

    def validate(limit)
      count, seconds = limit
      unless count.is_a?(Integer) && count.positive? && seconds.is_a?(Numeric) && seconds.positive? && seconds.finite?
        raise ArgumentError, "Rate limits require a positive count and finite interval"
      end

      # @type var result: [Integer, Float]
      result = [count, seconds.to_f]
      result.freeze
    end

    def reserve(operation)
      now = @clock.call
      keys = @limits.key?(operation) ? ["*", operation] : ["*"]
      delay = keys.map { |key| delay_for(key, now) }.max.to_f
      keys.each { |key| @history.fetch(key) << now } if delay.zero?
      delay
    end

    def delay_for(key, now)
      count, seconds = @limits.fetch(key)
      times = @history.fetch(key)
      times.reject! { |time| time <= now - seconds }
      times.size >= count ? times.fetch(0) + seconds - now : 0.0
    end
  end
end
