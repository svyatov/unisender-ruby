# frozen_string_literal: true

module Unisender
  class ClientClosedError < Error; end

  # Mutable resource lifetime is separate from immutable client options.
  class ClientState
    def initialize
      @closed = false
      @mutex = Mutex.new
    end

    def check_open!
      @mutex.synchronize { raise ClientClosedError, "Client is closed" if @closed }
    end

    def close
      @mutex.synchronize do
        return if @closed

        @closed = true
        yield
      end
    end
  end
end
