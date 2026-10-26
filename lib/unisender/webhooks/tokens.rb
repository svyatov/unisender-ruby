# frozen_string_literal: true

module Unisender
  module Webhooks
    # Scan strings and structural tokens once, preserving original byte offsets.
    class Tokens
      def initialize(text)
        @text = text
      end

      def each
        index = 0
        while index < @text.bytesize
          token, finish = read(index)
          yield token, index, finish if token.start_with?('"') || "{}[],".include?(token)
          index = finish
        end
      end

      private

      def read(index)
        finish = @text.getbyte(index) == 34 ? string_end(index + 1) : index + 1
        [@text.byteslice(index...finish).to_s, finish]
      end

      def string_end(index)
        while index < @text.bytesize
          byte = @text.getbyte(index)
          return index + 1 if byte == 34

          index += byte == 92 ? 2 : 1
        end
        raise WebhookError, :malformed_payload
      end
    end
  end
end
