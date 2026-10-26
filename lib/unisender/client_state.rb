# frozen_string_literal: true

module Unisender
  # The client has completed its resource lifetime.
  class ClientClosedError < Error
    def category
      :client_closed
    end
  end

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
