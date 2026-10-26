# frozen_string_literal: true

require "test_helper"
require "stringio"

class ExecutionIOTest < Minitest::Test
  def test_custom_transport_subclasses_keep_the_injection_contract
    transport_class = Class.new(Unisender::Transport) do
      def post(_uri, headers:, body:)
        raise "Missing request" if headers.empty? || body.empty?

        Unisender::HTTPResponse.new(status: 200, headers: {}, body: '{"result":[]}')
      end
    end
    client = Unisender::Client.new(api_key: "test", transport: transport_class.new)

    assert_empty client.with_execution(timeout: 1, &:get_lists)
  end

  def test_builtin_request_timeouts_use_remaining_budget
    http = FakeHTTP.new
    transport = Unisender::Transport.new(http_factory: ->(_) { http })
    client = Unisender::Client.new(api_key: "test", transport:)
    client.with_execution(timeout: 1, &:get_lists)

    assert_operator http.read_timeout, :<=, 1
    assert_operator http.open_timeout, :>, 0
  end

  def test_persistent_requests_also_clamp_reused_connections
    http = FakeHTTP.new
    transport = Unisender::PersistentTransport.new(http_factory: ->(_) { http })
    client = Unisender::Client.new(api_key: "test", transport:)
    client.with_execution(timeout: 1) { |scoped| 2.times { scoped.get_lists } }

    assert_operator http.write_timeout, :<=, 1
  ensure
    transport&.close
  end

  def test_download_cancellation_preserves_bytes_and_category
    token = Unisender::CancellationToken.new
    io = StringIO.new
    io.define_singleton_method(:write) { |bytes| super(bytes).tap { token.cancel } }
    downloader = Unisender::Downloader.new(resolver: ->(_) { ["93.184.216.34"] },
                                           http_factory: ->(*) { FakeHTTP.new })
    context = Unisender::ExecutionContext.new(timeout: 1, cancellation: token)
    error = assert_raises(Unisender::CancelledError) do
      downloader.download("https://files.example.test/file", io, max_bytes: 20, execution: context)
    end
    assert_equal ["abc", 3], [io.string, error.bytes_written]
  end

  def test_completed_task_download_passes_its_scope_to_builtin_downloader
    client = Unisender::Client.new(api_key: "test")
    downloader = Unisender::Downloader.new(resolver: ->(_) { ["93.184.216.34"] },
                                           http_factory: ->(*) { FakeHTTP.new })
    result = Unisender::TaskResult.new({ "status" => "completed",
                                         "file_to_download" => "https://files.example.test/file" })
    response = Unisender::TaskResultResponse.new(data: {}, status: 200, headers: {}, result:)
    client.with_execution(timeout: 1) do |scoped|
      task = Unisender::TaskResponse.new(response, client: scoped, task_uuid: "task")

      assert_equal 6, task.download_to(StringIO.new, max_bytes: 20, downloader:).bytes_written
    end
  end

  def test_nested_remaining_budget
    now = 0.0
    outer = Unisender::ExecutionContext.new(timeout: 1, clock: -> { now })
    inner = Unisender::ExecutionContext.new(timeout: 10, parent: outer, clock: -> { now })

    assert_in_delta(1.0, inner.remaining)
    assert_nil Unisender::ExecutionContext.new.remaining
  end

  def test_derived_client_cleanup
    client = Unisender::Client.new(api_key: "test")
    owned = nil
    client.with_execution do |scoped|
      owned = scoped.with(persistent: true).instance_variable_get(:@configuration)
    end
    assert_raises(Unisender::ClientClosedError) { owned.check_open! }
  end

  class FakeHTTP
    attr_accessor :use_ssl, :verify_mode, :open_timeout, :read_timeout, :write_timeout, :max_retries

    def start
      @started = true
      return yield self if block_given?

      self
    end

    def started?
      @started
    end

    def finish
      @started = false
    end

    def request(_request)
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.define_singleton_method(:body) { '{"result":[]}' }
      response.define_singleton_method(:read_body) { |&block| 2.times { block.call("abc") } }
      yield response if block_given?

      response
    end
  end
end
