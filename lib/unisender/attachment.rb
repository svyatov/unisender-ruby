# frozen_string_literal: true

module Unisender
  # A snapshot of binary data; reading an IO never transfers ownership.
  class Attachment
    attr_reader :filename, :bytes

    def initialize(filename:, bytes:)
      if filename.empty? || filename.match?(/[\[\]\r\n\0]/)
        raise ArgumentError, "Attachment filename must be nonempty without brackets or line breaks"
      end

      @filename = filename.dup.freeze
      @bytes = bytes.b.freeze
      freeze
    end

    def self.from_path(path, filename: File.basename(path))
      new(filename:, bytes: File.binread(path))
    rescue SystemCallError
      raise ArgumentError, "Attachment file could not be read", cause: nil
    end

    def self.from_io(io, filename:)
      bytes = io.read
      raise ArgumentError, "Attachment IO must return a string" unless bytes.is_a?(String)

      new(filename:, bytes:)
    end

    def inspect
      "#<Unisender::Attachment>"
    end
  end
end
