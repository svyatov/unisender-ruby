# frozen_string_literal: true

require "test_helper"
require "stringio"

class DownloadTargetTest < Minitest::Test
  def test_default_resolver_rejects_localhost
    target = Unisender::DownloadTarget.new(timeout: 1)

    error = assert_raises(Unisender::DownloadError) { target.resolve("https://localhost/export") }
    assert_equal :blocked_destination, error.reason
  end

  def test_rejects_private_and_mixed_resolution
    %w[127.0.0.1 10.0.0.1 169.254.169.254 ::1 ::ffff:127.0.0.1 fc00::1].each do |address|
      target = Unisender::DownloadTarget.new(timeout: 1, resolver: ->(_host) { ["93.184.216.34", address] })
      error = assert_raises(Unisender::DownloadError) { target.resolve("https://files.example.test/export") }

      assert_equal :blocked_destination, error.reason
    end
  end

  def test_rejects_invalid_urls_and_empty_resolution
    target = Unisender::DownloadTarget.new(timeout: 1, resolver: ->(_host) { [] })

    ["http://example.test", "https://user@example.test", "not a url", "https://example.test:8443"].each do |url|
      assert_raises(Unisender::DownloadError) { target.resolve(url) }
    end
    assert_raises(Unisender::DownloadError) { target.resolve("https://example.test") }
  end

  def test_invalid_address_and_resolver_failure_do_not_expose_the_url
    target = Unisender::DownloadTarget.new(timeout: 1, resolver: ->(_host) { ["invalid"] })

    assert_raises(Unisender::DownloadError) { target.resolve("https://example.test") }
    downloader = Unisender::Downloader.new(resolver: ->(_host) { raise IOError, "private" })
    error = assert_raises(Unisender::DownloadError) { downloader.download("https://example.test", StringIO.new, max_bytes: 1) }

    assert_equal [:transport, 0], [error.reason, error.bytes_written]
  end

  class ShortWriter
    attr_reader :output

    def initialize = @output = +""

    def write(value)
      @output << value[0]
      1
    end
  end

  def test_short_and_failed_writes_are_accounted_for
    destination = ShortWriter.new
    transfer = Unisender::DownloadTransfer.new(destination, 3)
    transfer.write("abc")

    assert_equal ["abc", 3], [destination.output, transfer.bytes_written]
    assert_raises(Unisender::DownloadError) { transfer.write("d") }
  end

  def test_zero_and_exceptional_writes_fail
    [0, IOError.new("private")].each do |result|
      destination = Object.new
      destination.define_singleton_method(:write) do |_value|
        raise result if result.is_a?(Exception)

        result
      end
      transfer = Unisender::DownloadTransfer.new(destination, 10)

      assert_raises(Unisender::DownloadError) { transfer.write("abc") }
    end
  end
end
