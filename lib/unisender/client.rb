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
      @execution = nil
      freeze
    end

    def inspect
      "#<Unisender::Client>"
    end

    private

    # @api private
    # Shared dispatcher for named operations and pagination.
    # @type method invoke: (String, params, ?required: Array[String], ?comma: Array[String]) -> Response
    def invoke(method, params, required: [], comma: [])
      params = prepare(method, params, required:, comma:)
      perform_request(method, params, named: true)
    rescue Error, ValidationError => e
      raise e.with_operation(method), cause: nil
    end

    def prepare(method, params, required: [], comma: [])
      params = message_defaults(params)
      params = Inputs.normalize(method, params)
      Validation.required!(params, required)
      Validation.operation!(method, params)
      comma_parameters(params, comma)
    rescue ValidationError => e
      raise e.with_operation(method), cause: nil
    end

    def comma_parameters(params, comma)
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

    public :invoke
  end
end
