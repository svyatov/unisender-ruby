# frozen_string_literal: true

module Unisender
  # Messages operations from the official UniSender API.
  class Client
    # https://www.unisender.com/ru/support/api/messages/cancel-campaign/
    def cancel_campaign(campaign_id:)
      params = { campaign_id: }
      invoke("cancelCampaign", params, required: %w[campaign_id])
    end

    # https://www.unisender.com/ru/support/api/messages/check-email/
    def check_email(email_id:)
      params = { email_id: }
      invoke("checkEmail", params, required: %w[email_id], comma: %w[email_id])
    end

    # https://www.unisender.com/ru/support/api/messages/check-sms/
    def check_sms(sms_id:)
      params = { sms_id: }
      invoke("checkSms", params, required: %w[sms_id])
    end

    # https://www.unisender.com/ru/support/api/messages/createcampaign/
    # rubocop:disable-next Metrics/ParameterLists -- Mirrors the documented operation.
    def create_campaign(message_id:, start_time: nil, timezone: nil, track_read: nil, track_links: nil,
                        contacts: nil, contacts_url: nil, track_ga: nil, payment_limit: nil, payment_currency: nil,
                        ga_medium: nil, ga_source: nil, ga_campaign: nil, ga_content: nil, ga_term: nil)
      params = { message_id:, start_time:, timezone:, track_read:, track_links:, contacts:, contacts_url:,
                 track_ga:, payment_limit:, payment_currency:, ga_medium:, ga_source:, ga_campaign:,
                 ga_content:, ga_term: }
      invoke("createCampaign", params, required: CAMPAIGN_REQUIRED, comma: %w[contacts])
    end

    # https://www.unisender.com/ru/support/api/messages/createemailmessage/
    # rubocop:disable Layout/LineLength -- The static annotation mirrors the complete keyword signature.
    # @type method create_email_message: (?sender_name: (String | Symbol)?, ?sender_email: (String | Symbol)?, list_id: id, ?subject: String | nil, ?body: String | nil, ?text_body: String | nil, ?generate_text: flag | nil, ?tag: String | nil, ?attachments: Hash[String, String] | Attachment | Array[Attachment] | nil, ?lang: String | Symbol | nil, ?template_id: id | nil, ?system_template_id: id | nil, ?wrap_type: String | nil, ?categories: String | Array[id] | nil) -> MessageCreatedResponse
    # rubocop:enable Layout/LineLength
    # rubocop:disable-next Metrics/ParameterLists -- Mirrors the documented operation.
    def create_email_message(list_id:, sender_name: UNSET, sender_email: UNSET, subject: nil, body: nil, text_body: nil,
                             generate_text: nil, tag: nil, attachments: nil, lang: UNSET, template_id: nil,
                             system_template_id: nil,
                             wrap_type: nil, categories: nil)
      params = { sender_name:, sender_email:, list_id:, subject:, body:, text_body:, generate_text:, tag:,
                 attachments:, lang:, template_id:, system_template_id:, wrap_type:, categories: }
      invoke("createEmailMessage", params, required: EMAIL_REQUIRED, comma: %w[categories])
    end

    # https://www.unisender.com/ru/support/api/messages/createsmsmessage/
    def create_sms_message(sender:, body:, list_id:, tag: nil)
      params = { sender:, body:, list_id:, tag: }
      invoke("createSmsMessage", params, required: %w[sender body list_id])
    end

    # https://www.unisender.com/ru/support/api/messages/deletemessage/
    def delete_message(message_id:)
      params = { message_id: }
      invoke("deleteMessage", params, required: %w[message_id])
    end
  end
end
