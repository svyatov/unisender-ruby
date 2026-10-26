# frozen_string_literal: true

module Unisender
  # Messages operations from the official UniSender API.
  class Client
    # https://www.unisender.com/ru/support/api/messages/get-actual-message-version/
    def get_actual_message_version(message_id:)
      params = { message_id: }
      invoke("getActualMessageVersion", params, required: %w[message_id])
    end

    # https://www.unisender.com/ru/support/api/messages/getwebversion/
    def get_web_version(campaign_id:)
      params = { campaign_id: }
      invoke("getWebVersion", params, required: %w[campaign_id])
    end

    # https://www.unisender.com/ru/support/api/messages/sendemail/
    # rubocop:disable Layout/LineLength -- The static annotation mirrors the complete keyword signature.
    # @type method send_email: (email: String, ?sender_name: (String | Symbol)?, ?sender_email: (String | Symbol)?, subject: String, body: String, list_id: id, ?attachments: Hash[String, String] | Attachment | Array[Attachment] | nil, ?lang: String | Symbol | nil, ?track_read: flag | nil, ?track_links: flag | nil, ?cc: String | nil, ?headers: String | params | nil, ?images_as: String | Symbol | nil, ?ref_key: String | nil, ?error_checking: flag | nil, ?metadata: params | nil, ?reply_to: String | nil, ?priority: String | nil) -> SendResponse
    # rubocop:enable Layout/LineLength
    # rubocop:disable-next Metrics/ParameterLists -- Mirrors the documented operation.
    def send_email(email:, subject:, body:, list_id:, sender_name: UNSET, sender_email: UNSET,
                   attachments: nil, lang: UNSET,
                   track_read: nil, track_links: nil, cc: nil, headers: nil, images_as: nil, ref_key: nil,
                   error_checking: true, metadata: nil, reply_to: nil, priority: nil)
      params = { email:, sender_name:, sender_email:, subject:, body:, list_id:, attachments:, lang:,
                 track_read:, track_links:, cc:, headers:, images_as:, ref_key:, error_checking:, metadata:,
                 reply_to:, priority: }
      invoke("sendEmail", params, required: %w[email sender_name sender_email subject body list_id])
    end

    # https://www.unisender.com/ru/support/api/messages/sendsms/
    def send_sms(phone:, sender:, text:)
      params = { phone:, sender:, text: }
      invoke("sendSms", params, required: %w[phone sender text])
    end

    # https://www.unisender.com/ru/support/api/messages/sendtestemail/
    def send_test_email(email:, id:)
      params = { email:, id: }
      invoke("sendTestEmail", params, required: %w[email id], comma: %w[email])
    end

    # https://www.unisender.com/ru/support/api/messages/updateemailmessage/
    # rubocop:disable-next Metrics/ParameterLists -- Mirrors the documented operation.
    def update_email_message(id:, sender_name: nil, sender_email: nil, subject: nil, body: nil, list_id: nil,
                             text_body: nil, lang: nil, categories: nil)
      params = { id:, sender_name:, sender_email:, subject:, body:, list_id:, text_body:, lang:, categories: }
      invoke("updateEmailMessage", params, required: %w[id], comma: %w[categories])
    end

    # https://www.unisender.com/ru/support/api/messages/updateoptinemail/
    def update_opt_in_email(sender_name:, sender_email:, subject:, body:, list_id:)
      params = { sender_name:, sender_email:, subject:, body:, list_id: }
      invoke("updateOptInEmail", params, required: %w[sender_name sender_email subject body list_id])
    end
  end
end
