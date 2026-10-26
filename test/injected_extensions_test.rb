# frozen_string_literal: true

require "test_helper"
require "unisender/testing"
require "stringio"

class InjectedExtensionsTest < Minitest::Test
  def test_legacy_retry_policy_and_limiter_inside_and_outside_scopes
    transport = Unisender::Testing::Transport.new
    2.times { transport.enqueue(data: { "result" => [] }) }
    client = Unisender::Client.new(api_key: "test", transport:, retry_policy: LegacyPolicy.new,
                                   rate_limiter: LegacyLimiter.new(global: [1, 1]))
    client.get_lists
    client.with_execution(timeout: 1, &:get_lists)

    assert_equal 2, transport.requests.size
  end

  def test_legacy_downloader_inside_and_outside_scopes
    client = Unisender::Client.new(api_key: "test")
    io = StringIO.new
    task(client).download_to(io, max_bytes: 4, downloader: LegacyDownloader.new)
    client.with_execution(timeout: 1) do |scoped|
      task(scoped).download_to(io, max_bytes: 4, downloader: LegacyDownloader.new)
    end

    assert_equal "dada", io.string
  end

  def task(client)
    result = Unisender::TaskResult.new({ "status" => "completed", "file_to_download" => "https://example.test/file" })
    response = Unisender::TaskResultResponse.new(data: {}, status: 200, headers: {}, result:)
    Unisender::TaskResponse.new(response, client:, task_uuid: "task")
  end

  class LegacyPolicy < Unisender::RetryPolicy
    def call(operation)
      raise "Unexpected operation" unless operation == "getLists"

      yield
    end
  end

  class LegacyLimiter < Unisender::RateLimiter
    def acquire(operation)
      raise "Unexpected operation" unless operation == "getLists"
    end
  end

  class LegacyDownloader < Unisender::Downloader
    def download(_url, io, max_bytes:)
      raise "Unexpected bound" unless max_bytes == 4

      io.write("da")
      Unisender::DownloadReceipt.new(bytes_written: 2, http_status: 200)
    end
  end
end
