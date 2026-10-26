# frozen_string_literal: true

module Unisender
  # Both responses are retained after a completed workflow.
  CampaignReceipt = Data.define(:message, :campaign)

  # A created message remains available when campaign creation fails.
  class CampaignWorkflowError < Error
    attr_reader :message_response, :error

    def initialize(message_response, error)
      @message_response = message_response
      @error = error
      super("Campaign creation failed after message creation")
    end

    def category
      error = @error
      error.is_a?(Error) || error.is_a?(ValidationError) ? error.category : :unexpected
    end

    def request_id
      error = @error
      error.request_id if error.is_a?(Error)
    end
  end

  # Validates both steps before creating a message.
  class Client
    def send_campaign(message:, campaign: {})
      message_params, campaign_params = campaign_parameters(message, campaign)
      created = invoke("createEmailMessage", message_params, required: EMAIL_REQUIRED) # : MessageCreatedResponse
      finish_campaign(created, campaign_params)
    end

    private

    def campaign_parameters(message, campaign)
      workflow_options!(message, campaign)

      defaults = { sender_name: UNSET, sender_email: UNSET, lang: UNSET }
      message_params = prepare("createEmailMessage", defaults.merge(message), required: EMAIL_REQUIRED,
                                                                              comma: %w[categories])
      campaign_params = prepare("createCampaign", campaign.merge(message_id: 0), required: CAMPAIGN_REQUIRED,
                                                                                 comma: %w[contacts])
      Form.encode(message_params)
      Form.encode(campaign_params)
      [message_params, campaign_params]
    end

    def workflow_options!(message, campaign)
      workflow_keys!(message, :create_email_message)
      workflow_keys!(campaign, :create_campaign)
      raise ArgumentError, "The workflow supplies message_id" if campaign.key?(:message_id)
    end

    def workflow_keys!(params, operation)
      allowed = method(operation).parameters.map(&:last)
      return if params.keys.all? { |key| allowed.include?(key) }

      raise ArgumentError, "Unknown workflow option"
    end

    def finish_campaign(created, params)
      response = invoke("createCampaign", params.merge(message_id: created.message_id),
                        required: CAMPAIGN_REQUIRED) # : CampaignCreatedResponse
      CampaignReceipt.new(message: created, campaign: response)
    rescue Error, ArgumentError => e
      raise CampaignWorkflowError.new(created, e), cause: nil
    end
  end
end
