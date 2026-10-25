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
    # rubocop:disable-next Metrics/ParameterLists -- Mirrors the documented operation.
    def send_email(email:, sender_name:, sender_email:, subject:, body:, list_id:, attachments: nil, lang: nil,
                   track_read: nil, track_links: nil, cc: nil, headers: nil, images_as: nil, ref_key: nil,
                   error_checking: nil, metadata: nil)
      params = { email:, sender_name:, sender_email:, subject:, body:, list_id:, attachments:, lang:,
                 track_read:, track_links:, cc:, headers:, images_as:, ref_key:, error_checking:, metadata: }
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
