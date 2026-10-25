# frozen_string_literal: true

require "time"

module Unisender
  # Explicit retry policy; never retries a request that can change server state.
  class RetryPolicy
    READ_ONLY = %w[
      getLists getTotalContactsCount getContactCount isContactInLists getContact checkEmail checkSms
      getActualMessageVersion getWebVersion getSenderDomainList getCampaignCommonStats getCampaignStatus
      getMessages getVisitedLinks listMessages getCampaigns getMessage getTemplate getTemplates listTemplates
      getFields getTags getContactFieldValues getSubscriberNote getSubscriberNotes async/getTaskResult
    ].freeze
    TRANSIENT_CODES = %w[retry_later api_call_limit_exceeded_for_api_key api_call_limit_exceeded_for_ip].freeze

    def initialize(max_retries: 0, max_elapsed: 60, clock: nil, sleeper: nil, random: nil)
      validate!(max_retries, max_elapsed)
      @max_retries = max_retries
      @max_elapsed = max_elapsed
      @clock = clock || -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
      @sleeper = sleeper || ->(delay) { sleep(delay) }
      @random = random || -> { rand }
      freeze
    end

    def call(operation)
      started = @clock.call
      attempts = 0
      begin
        yield
      rescue Error => e
        raise unless READ_ONLY.include?(operation) && attempts < @max_retries && transient?(e)

        raise unless wait?(e, attempts, started + @max_elapsed)

        attempts += 1
        retry
      end
    end

    private

    def validate!(max_retries, max_elapsed)
      unless max_retries.is_a?(Integer) && (0..2).cover?(max_retries)
        raise ArgumentError, "max_retries must be between 0 and 2"
      end
      return if max_elapsed.is_a?(Numeric) && max_elapsed.positive? && max_elapsed.finite?

      raise ArgumentError, "max_elapsed must be positive and finite"
    end

    def wait?(error, attempts, deadline)
      delay = [(2.0**attempts) + @random.call, retry_after(error)].max
      return false if delay > 30 || @clock.call + delay >= deadline

      @sleeper.call(delay)
      @clock.call < deadline
    end

    def transient?(error)
      case error
      when APIError then TRANSIENT_CODES.include?(error.code)
      when HTTPError then [429, 502, 503, 504].include?(error.response.status)
      when TimeoutError then true
      when TransportError then error.retryable?
      else false
      end
    end

    def retry_after(error)
      return 0.0 unless error.is_a?(HTTPError)

      value = error.response.headers["retry-after"]
      return 0.0 unless value
      return value.to_f if value.match?(/\A\d+(?:\.\d+)?\z/)

      [Time.httpdate(value) - Time.now, 0.0].max
    rescue ArgumentError
      0.0
    end
  end
end
