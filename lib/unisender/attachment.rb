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

    def self.from_path(path, filename: File.basename(path), max_bytes: nil)
      File.open(path, "rb") { |io| from_io(io, filename:, max_bytes:) }
    rescue SystemCallError
      raise ArgumentError, "Attachment file could not be read", cause: nil
    end

    def self.from_io(io, filename:, max_bytes: nil)
      size = read_size(max_bytes)
      bytes = size ? io.read(size) : io.read
      raise ArgumentError, "Attachment IO must return a string" unless bytes.is_a?(String)
      raise ValidationError.new(field: "attachments", code: :too_large) if max_bytes && bytes.bytesize > max_bytes

      new(filename:, bytes:)
    end

    def self.read_size(max_bytes)
      return nil if max_bytes.nil?
      unless max_bytes.is_a?(Integer) && max_bytes.positive?
        raise ValidationError.new(field: "max_bytes", code: :invalid_range)
      end

      max_bytes + 1
    end
    private_class_method :read_size

    def inspect
      "#<Unisender::Attachment>"
    end
  end
end
