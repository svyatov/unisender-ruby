# frozen_string_literal: true

module Unisender
  # Named input shapes are checked against the public RBS in the test suite.
  module OperationContracts
    # rubocop:disable Layout/LineLength -- Static input contracts mirror explicit public signatures.
    # @type var definitions: Hash[String, [String, Array[String], Hash[String, Array[String]]]]
    definitions = {
      "createList" => ["create_list", ["title"], { "title" => ["string"], "before_subscribe_url" => ["string"], "after_subscribe_url" => ["string"], "sub_user_rights" => ["hash"] }],
      "deleteList" => ["delete_list", ["list_id"], { "list_id" => %w[string integer] }],
      "exclude" => ["exclude", [], { "contact_type" => %w[string symbol], "contact" => ["string"], "email" => ["string"], "phone" => ["string"], "list_ids" => ["string", "array:string", "array:integer"] }],
      "async/exportContacts" => ["export_contacts", [], { "notify_url" => ["string"], "list_id" => %w[string integer], "field_names" => ["array:string"], "email" => ["string"], "phone" => ["string"], "tag" => ["string"], "email_status" => ["string"], "phone_status" => ["string"], "contact_status" => ["string"] }],
      "getContactCount" => ["get_contact_count", ["list_id"], { "list_id" => %w[string integer], "params" => ["hash"], "tag_id" => %w[string integer], "contact_type" => %w[string symbol], "search" => ["string"] }],
      "getLists" => ["get_lists", [], {}],
      "getTotalContactsCount" => ["get_total_contacts_count", ["login"], { "login" => ["string"] }],
      "importContacts" => ["import_contacts", [], { "field_names" => ["array:string"], "data" => ["array:array:parameter"], "records" => ["enumerable"], "overwrite_tags" => %w[boolean integer], "overwrite_lists" => %w[boolean integer], "telegram_bot_channel_id" => ["string"] }],
      "subscribe" => ["subscribe", ["list_ids"], { "list_ids" => ["string", "array:string", "array:integer"], "fields" => ["hash"], "email" => ["string"], "tags" => ["string", "array:string", "array:integer"], "double_optin" => %w[integer symbol], "overwrite" => %w[integer symbol] }],
      "updateList" => ["update_list", %w[list_id title], { "list_id" => %w[string integer], "title" => ["string"], "before_subscribe_url" => ["string"], "after_subscribe_url" => ["string"], "sub_user_rights" => ["hash"] }],
      "isContactInLists" => ["is_contact_in_lists", %w[email list_ids condition], { "email" => ["string"], "list_ids" => ["string", "array:string", "array:integer"], "condition" => ["string"] }],
      "getContact" => ["get_contact", ["email"], { "email" => ["string"], "include_lists" => %w[boolean integer], "include_fields" => %w[boolean integer], "include_details" => %w[boolean integer] }],
      "unsubscribe" => ["unsubscribe", [], { "contact_type" => %w[string symbol], "contact" => ["string"], "email" => ["string"], "phone" => ["string"], "list_ids" => ["string", "array:string", "array:integer"] }],
      "cancelCampaign" => ["cancel_campaign", ["campaign_id"], { "campaign_id" => %w[string integer] }],
      "checkEmail" => ["check_email", ["email_id"], { "email_id" => ["string", "array:string", "array:integer"] }],
      "checkSms" => ["check_sms", ["sms_id"], { "sms_id" => %w[string integer] }],
      "createCampaign" => ["create_campaign", ["message_id"], { "message_id" => %w[string integer], "start_time" => %w[string time], "timezone" => ["string"], "track_read" => %w[boolean integer], "track_links" => %w[boolean integer], "contacts" => ["string", "array:string", "array:integer"], "contacts_url" => ["string"], "track_ga" => %w[boolean integer], "payment_limit" => %w[integer float], "payment_currency" => ["string"], "ga_medium" => ["string"], "ga_source" => ["string"], "ga_campaign" => ["string"], "ga_content" => ["string"], "ga_term" => ["string"] }],
      "createEmailMessage" => ["create_email_message", %w[list_id sender_name sender_email], { "sender_name" => ["string"], "sender_email" => ["string"], "list_id" => %w[string integer], "subject" => ["string"], "body" => ["string"], "text_body" => ["string"], "generate_text" => %w[boolean integer], "tag" => ["string"], "attachments" => ["hash", "attachment", "array:attachment"], "lang" => ["string"], "template_id" => %w[string integer], "system_template_id" => %w[string integer], "wrap_type" => ["string"], "categories" => ["string", "array:string", "array:integer"] }],
      "createSmsMessage" => ["create_sms_message", %w[sender body list_id], { "sender" => ["string"], "body" => ["string"], "list_id" => %w[string integer], "tag" => ["string"] }],
      "deleteMessage" => ["delete_message", ["message_id"], { "message_id" => %w[string integer] }],
      "getActualMessageVersion" => ["get_actual_message_version", ["message_id"], { "message_id" => %w[string integer] }],
      "getWebVersion" => ["get_web_version", ["campaign_id"], { "campaign_id" => %w[string integer] }],
      "sendEmail" => ["send_email", %w[email subject body list_id sender_name sender_email], { "email" => ["string"], "sender_name" => ["string"], "sender_email" => ["string"], "subject" => ["string"], "body" => ["string"], "list_id" => %w[string integer], "attachments" => ["hash", "attachment", "array:attachment"], "lang" => ["string"], "track_read" => %w[boolean integer], "track_links" => %w[boolean integer], "cc" => ["string"], "headers" => %w[string hash], "images_as" => %w[string symbol], "ref_key" => ["string"], "error_checking" => %w[boolean integer], "metadata" => ["hash"], "reply_to" => ["string"], "priority" => ["string"] }],
      "sendSms" => ["send_sms", %w[phone sender text], { "phone" => ["string", "array:string"], "sender" => ["string"], "text" => ["string"] }],
      "sendTestEmail" => ["send_test_email", %w[email id], { "email" => ["string", "array:string", "array:integer"], "id" => %w[string integer] }],
      "updateEmailMessage" => ["update_email_message", ["id"], { "id" => %w[string integer], "sender_name" => ["string"], "sender_email" => ["string"], "subject" => ["string"], "body" => ["string"], "list_id" => %w[string integer], "text_body" => ["string"], "lang" => ["string"], "categories" => ["string", "array:string", "array:integer"] }],
      "updateOptInEmail" => ["update_opt_in_email", %w[sender_name sender_email subject body list_id], { "sender_name" => ["string"], "sender_email" => ["string"], "subject" => ["string"], "body" => ["string"], "list_id" => %w[string integer] }],
      "getSenderDomainList" => ["get_sender_domain_list", ["username"], { "username" => ["string"], "domain" => ["string"], "limit" => ["integer"], "offset" => ["integer"] }],
      "getCampaignCommonStats" => ["get_campaign_common_stats", ["campaign_id"], { "campaign_id" => %w[string integer] }],
      "async/getCampaignDeliveryStats" => ["get_campaign_delivery_stats", ["campaign_id"], { "campaign_id" => %w[string integer], "notify_url" => ["string"], "changed_since" => %w[string time], "field_ids" => ["array:string", "array:integer"] }],
      "getCampaignStatus" => ["get_campaign_status", ["campaign_id"], { "campaign_id" => %w[string integer] }],
      "getMessages" => ["get_messages", %w[date_from date_to], { "date_from" => %w[string time], "date_to" => %w[string time], "limit" => ["integer"], "offset" => ["integer"] }],
      "getVisitedLinks" => ["get_visited_links", ["campaign_id"], { "campaign_id" => %w[string integer], "group" => %w[boolean integer] }],
      "listMessages" => ["list_messages", %w[date_from date_to], { "date_from" => %w[string time], "date_to" => %w[string time], "limit" => ["integer"], "offset" => ["integer"] }],
      "getCampaigns" => ["get_campaigns", ["from"], { "from" => %w[string time], "to" => %w[string time], "limit" => ["integer"], "offset" => ["integer"] }],
      "getMessage" => ["get_message", ["id"], { "id" => %w[string integer] }],
      "async/getTaskResult" => ["get_task_result", ["task_uuid"], { "task_uuid" => ["string"] }],
      "createEmailTemplate" => ["create_email_template", %w[title subject body], { "title" => ["string"], "subject" => ["string"], "body" => ["string"], "description" => ["string"], "text_body" => ["string"], "lang" => ["string"] }],
      "deleteTemplate" => ["delete_template", ["template_id"], { "template_id" => %w[string integer] }],
      "getTemplate" => ["get_template", [], { "template_id" => %w[string integer], "system_template_id" => %w[string integer] }],
      "getTemplates" => ["get_templates", [], { "type" => %w[string symbol], "date_from" => %w[string time], "date_to" => %w[string time], "limit" => ["integer"], "offset" => ["integer"] }],
      "listTemplates" => ["list_templates", [], { "type" => %w[string symbol], "date_from" => %w[string time], "date_to" => %w[string time], "limit" => ["integer"], "offset" => ["integer"] }],
      "updateEmailTemplate" => ["update_email_template", ["template_id"], { "template_id" => %w[string integer], "title" => ["string"], "description" => ["string"], "subject" => ["string"], "body" => ["string"], "text_body" => ["string"], "lang" => ["string"] }],
      "createField" => ["create_field", %w[name type], { "name" => ["string"], "type" => ["string"], "public_name" => ["string"] }],
      "deleteField" => ["delete_field", ["id"], { "id" => %w[string integer] }],
      "deleteTag" => ["delete_tag", ["id"], { "id" => %w[string integer] }],
      "getFields" => ["get_fields", [], {}],
      "getTags" => ["get_tags", [], {}],
      "updateField" => ["update_field", %w[id name], { "id" => %w[string integer], "name" => ["string"], "public_name" => ["string"] }],
      "getContactFieldValues" => ["get_contact_field_values", %w[email field_ids], { "email" => ["string"], "field_ids" => ["string", "array:string", "array:integer"] }],
      "createSubscriberNote" => ["create_subscriber_note", %w[subscriber_id content], { "subscriber_id" => %w[string integer], "content" => ["string"] }],
      "updateSubscriberNote" => ["update_subscriber_note", %w[id content], { "id" => %w[string integer], "content" => ["string"] }],
      "deleteSubscriberNote" => ["delete_subscriber_note", ["id"], { "id" => %w[string integer] }],
      "getSubscriberNote" => ["get_subscriber_note", ["id"], { "id" => %w[string integer] }],
      "getSubscriberNotes" => ["get_subscriber_notes", ["subscriber_id"], { "subscriber_id" => %w[string integer], "limit" => ["integer"], "offset" => ["integer"], "order_type" => %w[string symbol], "order_by" => %w[string symbol], "is_pinned" => %w[boolean integer] }],
      "setHook" => ["set_hook", %w[hook_url events], { "hook_url" => ["string"], "events" => ["hash"], "event_format" => %w[symbol string], "max_parallel" => ["integer"], "single_event" => %w[boolean integer], "status" => %w[symbol string] }],
      "listHooks" => ["list_hooks", [], {}],
      "removeHook" => ["remove_hook", ["hook_url"], { "hook_url" => ["string"] }]
    }
    DEFINITIONS = definitions.transform_values(&:freeze).freeze
    # rubocop:enable Layout/LineLength

    def self.wire_name(name)
      entry = DEFINITIONS.find { |_wire, definition| definition.first == name.to_s }
      raise ArgumentError, "Unsupported named operation" unless entry

      entry.first
    end

    def self.validate!(wire, params)
      _name, required, types = DEFINITIONS.fetch(wire)
      validate_keys!(wire, params)
      params.each do |key, value|
        InputTypes.validate!(value, types.fetch(key.to_s), key.to_s) unless value.nil?
      end
      Validation.required!(params, required)
      extra = { "getContactCount" => %w[params], "subscribe" => %w[fields],
                "exclude" => %w[contact_type contact], "unsubscribe" => %w[contact_type contact] }
      Validation.required!(params, extra.fetch(wire, []))
    end

    def self.validate_keys!(wire, params)
      types = DEFINITIONS.fetch(wire).last
      return if params.keys.all? { |key| key.is_a?(Symbol) && types.key?(key.to_s) }

      raise ValidationError.new(field: "parameters", code: :unknown_keyword)
    end

    def self.comma_fields(wire)
      {
        "subscribe" => %w[list_ids tags], "exclude" => %w[list_ids], "unsubscribe" => %w[list_ids],
        "checkEmail" => %w[email_id], "createCampaign" => %w[contacts],
        "createEmailMessage" => %w[categories], "updateEmailMessage" => %w[categories],
        "sendTestEmail" => %w[email], "getContactFieldValues" => %w[field_ids]
      }.fetch(wire, [])
    end
  end
end
