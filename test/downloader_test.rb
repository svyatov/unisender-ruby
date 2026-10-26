# frozen_string_literal: true

require "test_helper"
require "stringio"
require_relative "support/download_https"

class DownloaderTest < Minitest::Test
  URL = "https://files.example.test/export?signature=private-token"

  def test_default_connection_factory_pins_the_resolved_address
    http = Unisender::Downloader.new.send(:configured_http, URI(URL), "93.184.216.34")

    assert_equal ["files.example.test", "93.184.216.34"], [http.address, http.ipaddr]
    assert_equal [true, OpenSSL::SSL::VERIFY_PEER, 0], [http.use_ssl?, http.verify_mode, http.max_retries]
  end

  def test_absent_or_non_numeric_content_length_is_allowed
    [nil, "invalid"].each do |length|
      reply = Net::HTTPOK.new("1.1", "200", "OK")
      reply["content-length"] = length
      reply.define_singleton_method(:read_body) { |&block| block.call("abc") }
      transfer = Unisender::DownloadTransfer.new(StringIO.new, 3)
      Unisender::Downloader.new.send(:stream, reply, transfer)

      assert_equal 3, transfer.bytes_written
    end
  end

  def test_download_streams_without_credentials_or_closing_the_destination
    server = DownloadHTTPS.new
    io = StringIO.new
    receipt = downloader(server).download(URL, io, max_bytes: 100)
    headers = server.requests.pop.join

    assert_equal ["file data", 9, 200, false], [io.string, receipt.bytes_written, receipt.http_status, io.closed?]
    refute_match(/Authorization|api_key|Bearer/, headers)
  ensure
    server&.close
  end

  def test_rejects_redirects_without_following_them
    server = DownloadHTTPS.new(status: 302)
    error = assert_raises(Unisender::DownloadError) { downloader(server).download(URL, StringIO.new, max_bytes: 100) }

    assert_equal [:http_error, 302, 0], [error.reason, error.http_status, error.bytes_written]
    refute_includes error.message, "private-token"
  ensure
    server&.close
  end

  def test_truncated_body_keeps_the_confirmed_byte_count
    server = DownloadHTTPS.new(body: "abc", length: 10)
    error = assert_raises(Unisender::DownloadError) { downloader(server).download(URL, StringIO.new, max_bytes: 100) }

    assert_equal [:incomplete, 3], [error.reason, error.bytes_written]
  ensure
    server&.close
  end

  def test_body_bound_and_invalid_controls
    server = DownloadHTTPS.new(body: "longer than limit")
    error = assert_raises(Unisender::DownloadError) { downloader(server).download(URL, StringIO.new, max_bytes: 1) }

    assert_equal :too_large, error.reason
  ensure
    server&.close
  end

  def test_invalid_download_controls
    assert_raises(ArgumentError) { Unisender::Downloader.new(open_timeout: 0) }
    assert_raises(ArgumentError) { Unisender::Downloader.new.download(URL, StringIO.new, max_bytes: 0) }
  end

  private

  def downloader(server)
    Unisender::Downloader.new(resolver: ->(_host) { ["93.184.216.34"] }, http_factory: lambda { |_uri, address|
      raise "Address was not pinned" unless address == "93.184.216.34"

      http = Net::HTTP.new("localhost", server.port, nil)
      http.cert_store = server.store
      http
    })
  end
end
