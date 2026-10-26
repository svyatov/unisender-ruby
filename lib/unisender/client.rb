# frozen_string_literal: true

module Unisender
  # Synchronous client for the documented UniSender API.
  class Client
    RESERVED_PARAMETERS = %w[api_key format].freeze
    TASK_METHODS = %w[async/exportContacts async/getCampaignDeliveryStats async/getTaskResult].freeze
    UNSET = :__unisender_unset__
    EMAIL_REQUIRED = %w[sender_name sender_email list_id].freeze
    CAMPAIGN_REQUIRED = %w[message_id].freeze

    # @type method initialize: (api_key: String, **config_value) -> void
    def initialize(api_key:, **)
      @configuration = Configuration.new(api_key:, **)
      @api_key = @configuration.api_key
      @language = @configuration.language
      @transport = @configuration.transport
      @retry_policy = @configuration.retry_policy
      freeze
    end

    def request(method, params: {})
      validate_request(method, params)
      uri, headers, body = request_values(method, params)
      attempt = 0
      @retry_policy.call(method) do
        attempt += 1
        exchange(method, uri, headers:, body:, attempt:) { |response| Protocol.parse(response, method:) }
      end
    rescue Error => e
      raise e.with_operation(method), cause: nil
    end

    def inspect
      "#<Unisender::Client>"
    end

    private

    def request_values(method, params)
      uri = URI("https://api.unisender.com/#{@language}/api/#{method}")
      headers = { "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8" }
      body = Form.encode(params.merge("api_key" => @api_key, "format" => "json"))
      [uri, headers, body]
    end

    # rubocop:disable-next Metrics/MethodLength -- Start the clock outside request failure handling.
    def exchange(operation, uri, headers:, body:, attempt: 1)
      @configuration.check_open!
      limiter = @configuration.rate_limiter
      limiter.acquire(operation) if limiter && operation != "track_events"
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = nil
      begin
        response = @transport.post(uri, headers:, body:)
        result = yield response
      rescue StandardError => e
        observe(operation, attempt, started, response, e)
        raise
      end
      observe(operation, attempt, started, response, nil)
      result
    end

    def observe(operation, attempt, started, response, error)
      event = Observation.event(operation, attempt, started, response, error)
      Observation.emit(@configuration.instrumentation, event)
    end

    def validate_request(method, params)
      raise ArgumentError, "Invalid API method name" unless method.match?(%r{\A(?:async/)?[A-Za-z][A-Za-z0-9]*\z})
      return unless params.keys.any? { |key| RESERVED_PARAMETERS.include?(key.to_s) }

      raise ArgumentError, "api_key and format are managed by the client"
    end

    # The wire response stays JSON; each named operation declares the documented result type.
    # @type method invoke: (String, params, ?required: Array[String], ?comma: Array[String]) -> Response
    def invoke(method, params, required: [], comma: [])
      params = prepare(method, params, required:, comma:)
      response = Results.build(method, request(method, params:))
      bind_task(method, response, params)
    rescue Error => e
      raise e.with_operation(method), cause: nil
    end

    def prepare(method, params, required: [], comma: [])
      params = message_defaults(params)
      params = Inputs.normalize(method, params)
      Validation.required!(params, required)
      Validation.operation!(method, params)
      comma.each do |name|
        value = params[name.to_sym]
        params[name.to_sym] = Validation.comma_list(value) if value.is_a?(Array)
      end
      params
    end

    def message_defaults(params)
      params.to_h do |key, value|
        default = @configuration.message_defaults[key.to_s.to_sym] if value == UNSET
        [key, value == UNSET ? default : value]
      end
    end

    def bind_task(method, response, params)
      return response unless TASK_METHODS.include?(method)

      task = response # : TaskResultResponse
      uuid = params[:task_uuid] || task.task_uuid
      raise InvalidResponseError, "Missing task UUID" unless uuid.is_a?(String)

      TaskResponse.new(task, client: self, task_uuid: uuid)
    end
  end
end
