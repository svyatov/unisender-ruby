# frozen_string_literal: true

require "net/http"
require "openssl"

module Unisender
  DownloadReceipt = Data.define(:bytes_written, :http_status)

  # A failed transfer can leave a partial result in the caller's destination.
  class DownloadError < Error
    attr_reader :reason, :bytes_written, :http_status

    def category
      :download
    end

    def initialize(reason:, bytes_written: 0, http_status: nil)
      @reason = reason
      @bytes_written = bytes_written
      @http_status = http_status
      super("Download failed: #{reason}")
    end
  end

  # Downloads use a separate credential-free connection and never follow redirects.
  class Downloader
    def initialize(open_timeout: 5, read_timeout: 60, write_timeout: 30, resolver: nil, http_factory: nil)
      unless [open_timeout, read_timeout, write_timeout].all? do |value|
        value.is_a?(Numeric) && value.positive? && value.finite?
      end
        raise ArgumentError, "Download timeouts must be positive and finite"
      end

      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @write_timeout = write_timeout
      @target = DownloadTarget.new(timeout: open_timeout, resolver:)
      @http_factory = http_factory || ->(uri, address) { build_http(uri, address) }
    end

    def download(url, io, max_bytes:)
      transfer = DownloadTransfer.new(io, max_bytes)
      execute(url, transfer)
    end

    private

    def execute(url, transfer)
      response = download_response(url, transfer)
      DownloadReceipt.new(bytes_written: transfer.bytes_written, http_status: response.code.to_i)
    rescue DownloadError => e
      raise DownloadError.new(reason: e.reason, bytes_written: transfer.bytes_written, http_status: e.http_status),
            cause: nil
    rescue StandardError
      raise DownloadError.new(reason: :transport, bytes_written: transfer.bytes_written), cause: nil
    end

    def download_response(url, transfer)
      uri, address = @target.resolve(url)
      http = configured_http(uri, address)
      http.start do |connection|
        request = Net::HTTP::Get.new(uri, { "Accept-Encoding" => "identity" })
        connection.request(request) { |reply| stream(reply, transfer) }
      end
    end

    def build_http(uri, address)
      http = Net::HTTP.new(uri.hostname.to_s, uri.port, nil)
      http.ipaddr = address
      http
    end

    def configured_http(uri, address)
      http = @http_factory.call(uri, address)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout
      http.write_timeout = @write_timeout
      http.max_retries = 0
      http
    end

    def stream(response, transfer)
      status = response.code.to_i
      raise DownloadError.new(reason: :http_error, http_status: status) unless (200..299).cover?(status)

      response.read_body { |chunk| transfer.write(chunk) }
      length = response["content-length"]
      return unless length&.match?(/\A\d+\z/) && transfer.bytes_written != length.to_i

      raise DownloadError.new(reason: :incomplete)
    end
  end
end
