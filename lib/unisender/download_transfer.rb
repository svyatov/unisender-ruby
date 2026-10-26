# frozen_string_literal: true

module Unisender
  # Counts only writes acknowledged by the caller-owned destination.
  class DownloadTransfer
    attr_reader :bytes_written

    def initialize(io, max_bytes)
      raise ArgumentError, "max_bytes must be a positive integer" unless max_bytes.is_a?(Integer) && max_bytes.positive?

      @io = io
      @max_bytes = max_bytes
      @bytes_written = 0
    end

    def write(chunk)
      raise DownloadError.new(reason: :too_large) if @bytes_written + chunk.bytesize > @max_bytes

      copy_chunk(chunk)
    rescue DownloadError
      raise
    rescue StandardError
      raise DownloadError.new(reason: :write_failed), cause: nil
    end

    private

    def copy_chunk(chunk)
      offset = 0
      while offset < chunk.bytesize
        part = chunk.byteslice(offset..).to_s
        written = @io.write(part)
        raise DownloadError.new(reason: :write_failed) unless written.positive? && written <= part.bytesize

        offset += written
        @bytes_written += written
      end
    end
  end
end
