# frozen_string_literal: true

module Unisender
  # Serializes requests per client and reuses verified HTTPS connections.
  class PersistentTransport < Transport
    Connection = Data.define(:http, :used_at)
    HOSTS = %w[api.unisender.com event.unisender.com].freeze

    # rubocop:disable-next Metrics/ParameterLists -- Preserves transport injection and explicit timeouts.
    def initialize(idle_timeout: 30, clock: nil, pid: nil, open_timeout: 5, read_timeout: 60,
                   write_timeout: 30, http_factory: nil)
      unless idle_timeout.is_a?(Numeric) && idle_timeout.positive? && idle_timeout.finite?
        raise ArgumentError, "idle_timeout must be positive and finite"
      end

      super(open_timeout:, read_timeout:, write_timeout:, http_factory:)
      @idle_timeout = idle_timeout
      initialize_pool(clock, pid)
    end

    def initialize_pool(clock, pid)
      @clock = clock || -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
      @pid_source = pid || -> { Process.pid }
      @pid = @pid_source.call
      @connections = {}
      @mutex = Mutex.new
      @closed = false
    end

    def close
      reset_after_fork
      @mutex.synchronize do
        @closed = true
        # rubocop:disable-next Style/HashEachMethods -- Snapshot keys before removing pooled entries.
        @connections.keys.each { |key| discard(key) }
      end
      nil
    end

    def inspect
      "#<Unisender::PersistentTransport>"
    end

    private

    def perform(uri, request, execution:)
      reset_after_fork
      key = origin(uri)
      @mutex.synchronize do
        raise TransportError, "Transport is closed" if @closed

        execution&.check!
        send_request(key, uri, request, execution)
      end
    end

    def send_request(key, uri, request, execution)
      http = connection(key, uri, execution)
      configure_timeouts(http, execution)
      response = http.request(request)
      @connections[key] = Connection.new(http:, used_at: @clock.call)
      response
    rescue StandardError
      discard(key)
      raise
    end

    def origin(uri)
      unless uri.scheme == "https" && uri.port == 443 && HOSTS.include?(uri.hostname)
        raise ArgumentError, "Persistent transport requires a UniSender API origin"
      end

      uri.hostname.to_s
    end

    def connection(key, uri, execution)
      current = @connections[key]
      return current.http if current && @clock.call - current.used_at < @idle_timeout

      discard(key)
      http = configured_http(uri, execution:)
      http.start
      @connections[key] = Connection.new(http:, used_at: @clock.call)
      http
    end

    def discard(key)
      http = @connections.delete(key)&.http
      http.finish if http&.started?
    rescue IOError, SystemCallError, OpenSSL::SSL::SSLError
      nil
    end

    def reset_after_fork
      current = @pid_source.call
      return if @pid == current

      # rubocop:disable-next Style/HashEachMethods -- Snapshot keys before removing pooled entries.
      @connections.keys.each { |key| discard(key) }
      @pid = current
      @mutex = Mutex.new
    end
  end
end
