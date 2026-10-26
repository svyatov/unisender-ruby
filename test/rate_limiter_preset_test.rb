# frozen_string_literal: true

require "test_helper"

class RateLimiterPresetTest < Minitest::Test
  # https://www.unisender.com/ru/support/api/common/api-limits/
  BUDGETS = { "getLists" => 1200, "subscribe" => 300, "async/exportContacts" => 20,
              "getContactCount" => 60, "createCampaign" => 100, "checkEmail" => 300,
              "sendEmail" => 60, "sendSms" => 300 }.freeze

  BUDGETS.each do |operation, count|
    define_method("test_#{operation.tr('/', '_')}_preset_boundary") do
      time = 0.0
      sleeps = []
      limiter = Unisender::RateLimiter.unisender(clock: -> { time }, sleeper: lambda { |delay|
        sleeps << delay
        time += delay
      })
      count.times { limiter.acquire(operation) }

      assert_empty sleeps
      limiter.acquire(operation)

      assert_equal [60.0], sleeps
    end
  end
end
